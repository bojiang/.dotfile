/**
 * Bridge the shared Claude/Codex lifecycle scripts into Pi's extension events.
 *
 * Pi does not read ~/.claude/settings.json or ~/.codex/hooks.json.  Keep the
 * scripts in ~/.claude/hooks as the single implementation and adapt Pi events
 * to the JSON payload shape those scripts already consume.
 */
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const hooksDir = join(homedir(), ".claude", "hooks");
const sessionLoadContext = join(hooksDir, "session-load-context.sh");
const confirmo = join(hooksDir, "confirmo.sh");
const trackStateWrite = join(hooksDir, "track-state-write.sh");

interface HookPayload {
  hook_event_name: "SessionStart" | "UserPromptSubmit" | "PreToolUse" | "PostToolUse" | "SessionEnd";
  session_id: string;
  cwd: string;
  tool_name?: string;
  tool_input?: unknown;
}

async function runHook(script: string, payload: HookPayload, timeout = 5_000): Promise<string> {
  return new Promise((resolve) => {
    let stdout = "";
    let settled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const finish = (value = "") => {
      if (settled) return;
      settled = true;
      if (timer) clearTimeout(timer);
      resolve(value);
    };
    let child;
    try {
      child = spawn(script, [], { stdio: ["pipe", "pipe", "ignore"] });
    } catch {
      finish();
      return;
    }
    timer = setTimeout(() => {
      child.kill();
      finish();
    }, timeout);
    child.stdout.on("data", (chunk: Buffer) => {
      if (stdout.length < 64 * 1024) stdout += chunk.toString();
    });
    child.on("error", () => finish());
    child.on("close", (code) => finish(code === 0 ? stdout : ""));
    child.stdin.end(JSON.stringify(payload));
  });
}

export default function (pi: ExtensionAPI) {
  let startupContext = "";
  let startupContextSent = false;

  pi.on("session_start", async (_event, ctx) => {
    const payload: HookPayload = {
      hook_event_name: "SessionStart",
      session_id: ctx.sessionManager.getSessionId(),
      cwd: ctx.cwd,
    };
    await runHook(confirmo, payload);
    const output = await runHook(sessionLoadContext, payload, 10_000);
    try {
      startupContext = JSON.parse(output).hookSpecificOutput?.additionalContext ?? "";
    } catch {
      startupContext = "";
    }
  });

  pi.on("input", async (event, ctx) => {
    // Extension-generated follow-ups are not a new human turn and must not
    // reset the state-write fuse.
    if (event.source === "extension") return;
    const payload: HookPayload = {
      hook_event_name: "UserPromptSubmit",
      session_id: ctx.sessionManager.getSessionId(),
      cwd: ctx.cwd,
    };
    await runHook(confirmo, payload);
    await runHook(trackStateWrite, payload);
  });

  pi.on("before_agent_start", async (_event, _ctx) => {
    if (!startupContext || startupContextSent) return;
    startupContextSent = true;
    return {
      message: {
        customType: "dotfile-session-context",
        content: startupContext,
        display: false,
      },
    };
  });

  pi.on("tool_call", async (event, ctx) => {
    await runHook(confirmo, {
      hook_event_name: "PreToolUse",
      session_id: ctx.sessionManager.getSessionId(),
      cwd: ctx.cwd,
      tool_name: event.toolName,
      tool_input: event.input,
    });
  });

  pi.on("tool_result", async (event, ctx) => {
    const payload: HookPayload = {
      hook_event_name: "PostToolUse",
      session_id: ctx.sessionManager.getSessionId(),
      cwd: ctx.cwd,
      tool_name: event.toolName,
      tool_input: event.input,
    };
    await runHook(confirmo, payload);
    await runHook(trackStateWrite, payload);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    await runHook(confirmo, {
      hook_event_name: "SessionEnd",
      session_id: ctx.sessionManager.getSessionId(),
      cwd: ctx.cwd,
    });
  });
}
