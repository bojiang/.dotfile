#!/usr/bin/env bash
# Stop-hook fuse shared by Claude Code and Codex. Tool hooks keep the state so
# this script does not depend on either product's unstable transcript format.

INPUT=$(cat -)

python3 - "$INPUT" <<'EOF'
import json
import os
import re
import sys
import tempfile

try:
    data = json.loads(sys.argv[1])
except (IndexError, json.JSONDecodeError):
    sys.exit(0)
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

session_id = str(data.get("session_id") or "")
if not session_id:
    sys.exit(0)

state_dir = os.path.join(
    os.environ.get("TMPDIR") or tempfile.gettempdir(),
    "agent-state-write-fuse",
)
safe_session_id = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id)
state_path = os.path.join(state_dir, safe_session_id + ".json")
try:
    with open(state_path) as f:
        state = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)

if state.get("edited") and not state.get("dispatched"):
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
