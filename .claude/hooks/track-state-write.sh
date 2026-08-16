#!/usr/bin/env bash

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

session_id = str(data.get("session_id") or "")
if not session_id:
    sys.exit(0)

state_dir = os.path.join(
    os.environ.get("TMPDIR") or tempfile.gettempdir(),
    "agent-state-write-fuse",
)
os.makedirs(state_dir, exist_ok=True)
safe_session_id = re.sub(r"[^A-Za-z0-9_.-]", "_", session_id)
state_path = os.path.join(state_dir, safe_session_id + ".json")

event = data.get("hook_event_name")
if event == "UserPromptSubmit":
    state = {"edited": False, "dispatched": False}
elif event == "PostToolUse":
    try:
        with open(state_path) as f:
            state = json.load(f)
    except (OSError, json.JSONDecodeError):
        state = {"edited": False, "dispatched": False}

    tool_name = str(data.get("tool_name") or "")
    tool_input = data.get("tool_input") or {}
    serialized_input = json.dumps(tool_input, ensure_ascii=False)
    normalized_name = tool_name.lower().replace("-", "_")

    if (
        normalized_name.endswith(("spawn_agent", "task", "agent"))
        and re.search(r"state[-_]keeper", serialized_input, re.IGNORECASE)
    ):
        state["dispatched"] = True

    direct_edit_tools = {
        "apply_patch",
        "edit",
        "write",
        "multiedit",
        "notebookedit",
    }
    uses_apply_patch = (
        normalized_name in direct_edit_tools
        or (
            normalized_name.endswith("exec")
            and re.search(r"tools\.apply_patch\s*\(", serialized_input)
        )
    )

    if uses_apply_patch:
        paths = re.findall(
            r"^\*\*\* (?:Add|Update|Delete) File: (.+)$",
            serialized_input.replace("\\n", "\n"),
            re.MULTILINE,
        )
        if not paths and isinstance(tool_input, dict):
            paths = [
                value
                for key in ("file_path", "notebook_path", "path")
                if isinstance((value := tool_input.get(key)), str)
            ]

        def ignored(path):
            normalized = path.replace("\\", "/")
            return (
                normalized.startswith(("/tmp/", "/private/tmp/"))
                or normalized.startswith(".agent/")
                or "/.agent/" in normalized
            )

        if not paths or any(not ignored(path) for path in paths):
            state["edited"] = True
else:
    sys.exit(0)

temp_path = state_path + ".tmp." + str(os.getpid())
with open(temp_path, "w") as f:
    json.dump(state, f)
os.replace(temp_path, state_path)
EOF
