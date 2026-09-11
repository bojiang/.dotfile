# Knowledge-Persistence Mechanism (state-keeper + Stop-hook fuse)

## How it works
1. At task wrap-up, the main model judges whether costly-and-stable conclusions exist.
2. If yes, it dispatches the `state-keeper` subagent with (conclusion / why / affected files); the subagent writes .agent/state/, keeping main-session context short.
3. A Stop-hook fuse (`enforce-state-write.sh`) blocks at most once per turn when code was edited in an .agent project without a state-keeper dispatch.

Design rationale (why the fuse only forces a judgment, and which alternatives were rejected): see [rejected-alternatives.md](rejected-alternatives.md).

## State kind taxonomy (user decision, 2026-08-13)
Kinds are {requirements, usage, implementation} — `design/` no longer exists as a kind.
- usage/ — operating reference for agents using the system: invocation, commands, entry points
- design trade-offs and rejected alternatives are recorded under implementation/
Rationale: future agents need "how to use" far more than design history. Do not reintroduce design/.
Encoded in .claude/CLAUDE.md (`# 目录` section) and .claude/agents/state-keeper.md (routing rule).

## Files
- .claude/hooks/enforce-state-write.sh — the fuse
- .claude/hooks/session-load-context.sh — shared SessionStart loader: injects `$CWD/.agent/state/INDEX.md`, the lexically sorted first-level state topic names, and the latest three backlog names. Its cwd-only lookup is correct by design: `.agent` lives at $CWD per user 2026-08-14; the fuse/state-keeper walking parents is the deviation — see known-gaps.md.
- .claude/agents/state-keeper.md — the writer subagent (holds the kind routing rule)
- .claude/CLAUDE.md — `# 目录` section, last 3 lines (avoid auto-memory; use .agent structure)
- .claude/settings.json — hook registration, version-managed in repo; hook commands use $HOME-based paths (repo is public, shared across macOS/Linux — no /opt/homebrew or /Users/bjiang absolutes)
- .codex/hooks.json — registers the same SessionStart loader for Codex.
- .pi/extensions/state-hooks.ts — invokes the same loader on Pi's `session_start` event and forwards its returned context to the first agent turn.
- .claude/hooks/confirmo.sh — guard script for the machine-optional confirmo tool; exits 0 when ~/.confirmo or node is absent
- init.sh — installs the global Claude, Codex, and Pi hook wiring: it symlinks `.claude/{CLAUDE.md,hooks,agents,settings.json}` into `~/.claude`, `.codex/hooks.json` into `~/.codex`, and `.pi/extensions/state-hooks.ts` into Pi's extension directory.

## SessionStart scope
The shared context loader applies to Claude Code, Codex, and Pi when their
corresponding global configuration or extension is installed by `init.sh`. It
returns no injected context unless the session CWD contains `.agent/state/`.
