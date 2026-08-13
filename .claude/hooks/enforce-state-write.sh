#!/usr/bin/env bash
# Stop-hook fuse: when code was edited this turn in an .agent project and no
# state-keeper was dispatched, block once so the main model makes the
# persist-or-not judgment. Judgment is the model's; this only guarantees it happens.

INPUT=$(cat -)

python3 - "$INPUT" <<'EOF'
import json, os, sys

data = json.loads(sys.argv[1])
if data.get("stop_hook_active"):
    sys.exit(0)

d = data.get("cwd") or ""
home = os.path.expanduser("~")
agent_dir = None
while d and d not in ("/", home):
    if os.path.isdir(os.path.join(d, ".agent")):
        agent_dir = os.path.join(d, ".agent")
        break
    d = os.path.dirname(d)
if not agent_dir:
    sys.exit(0)

tp = data.get("transcript_path") or ""
if not os.path.isfile(tp):
    sys.exit(0)

EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
SKIP_PREFIXES = ("/tmp/", "/private/tmp/")

edited = dispatched = False
with open(tp) as f:
    for line in f:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        msg = entry.get("message") or {}
        content = msg.get("content")

        # a real user prompt starts a new turn: reset counters
        if entry.get("type") == "user":
            if isinstance(content, str) or (
                isinstance(content, list)
                and any(b.get("type") == "text" for b in content if isinstance(b, dict))
            ):
                edited = dispatched = False
            continue

        if entry.get("type") != "assistant" or not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict) or block.get("type") != "tool_use":
                continue
            name = block.get("name", "")
            inp = block.get("input") or {}
            if name in EDIT_TOOLS:
                path = inp.get("file_path") or inp.get("notebook_path") or ""
                if "/.agent/" not in path and not path.startswith(SKIP_PREFIXES):
                    edited = True
            elif name in ("Task", "Agent") and "state-keeper" in json.dumps(inp):
                dispatched = True

if edited and not dispatched:
    print(json.dumps({
        "decision": "block",
        "reason": (
            "Code was modified this turn and no state-keeper dispatch was seen. "
            "Judge: did this turn produce conclusions that were costly to obtain and remain stable, "
            "and are missing from .agent/state? If yes, dispatch the state-keeper subagent with "
            "(conclusion / why / affected files). If no, simply stop again."
        ),
    }))
EOF
