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
- .claude/hooks/session-load-context.sh — SessionStart auto-load of state/INDEX.md (cwd-only, correct by design: `.agent` lives at $CWD per user 2026-08-14; the fuse/state-keeper walking parents is the deviation — see known-gaps.md)
- .claude/agents/state-keeper.md — the writer subagent (holds the kind routing rule)
- .claude/CLAUDE.md — `# 目录` section, last 3 lines (avoid auto-memory; use .agent structure)
- .claude/settings.json — hook registration, version-managed in repo; hook commands use $HOME-based paths (repo is public, shared across macOS/Linux — no /opt/homebrew or /Users/bjiang absolutes)
- .claude/hooks/confirmo.sh — guard script for the machine-optional confirmo tool; exits 0 when ~/.confirmo or node is absent
- init.sh — symlinks .claude/{CLAUDE.md,hooks,agents,settings.json} into ~/.claude (backup+symlink pattern)
