# Knowledge-Persistence Mechanism (state-keeper + Stop-hook fuse)

## How it works
1. At task wrap-up, the main model judges whether costly-and-stable conclusions exist.
2. If yes, it dispatches the `state-keeper` subagent with (conclusion / why / affected files); the subagent writes .agent/state/, keeping main-session context short.
3. A Stop-hook fuse (`enforce-state-write.sh`) blocks at most once per turn when code was edited in an .agent project without a state-keeper dispatch.

Design rationale (why the fuse only forces a judgment, and which alternatives were rejected): see [../design/rejected-alternatives.md](../design/rejected-alternatives.md).

## Files
- .claude/hooks/enforce-state-write.sh — the fuse
- .claude/agents/state-keeper.md — the writer subagent
- .claude/CLAUDE.md — `# 目录` section, last 3 lines (avoid auto-memory; use .agent structure)
- init.sh — symlinks .claude/agents into ~/.claude/agents
