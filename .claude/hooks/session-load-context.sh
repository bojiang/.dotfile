#!/usr/bin/env bash
# Read .agent/state/INDEX.md and recent backlogs at session start

CWD=$(cat - | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))")
AGENT_DIR="$CWD/.agent"

CONTEXT=""

# Load state index
STATE_INDEX="$AGENT_DIR/state/INDEX.md"
if [ -f "$STATE_INDEX" ]; then
  CONTEXT+="=== Project State Index ===
$(cat "$STATE_INDEX")
"
fi

# Load state topic names
STATE_DIR="$AGENT_DIR/state"
if [ -d "$STATE_DIR" ]; then
  TOPICS=$(find "$STATE_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
  if [ -n "$TOPICS" ]; then
    CONTEXT+="
=== State Topics ===
$TOPICS"
  fi
fi

# Load recent 3 backlogs (by directory name, sorted reverse)
BACKLOG_DIR="$AGENT_DIR/backlogs"
if [ -d "$BACKLOG_DIR" ]; then
  RECENT=$(ls -d "$BACKLOG_DIR"/*/ 2>/dev/null | sort -r | head -3 | xargs -I{} basename {})
  if [ -n "$RECENT" ]; then
    CONTEXT+="
=== Recent Backlogs (latest 3) ===
$RECENT"
  fi
fi

if [ -z "$CONTEXT" ]; then
  exit 0
fi

# Escape for JSON
ESCAPED=$(python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" <<< "$CONTEXT")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": $ESCAPED
  }
}
EOF
