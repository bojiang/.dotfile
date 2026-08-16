# 002 — Codex Global Instructions & Hooks

Date: 2026-08-16
Status: implemented and installed; Codex restart/trust review pending

## Summary

Share the global Claude Code instructions with Codex and provide equivalent
Codex lifecycle hooks without linking the incompatible Claude settings file.

## Changes made

### 1. Shared global instructions

- `init.sh` now backs up `~/.codex/AGENTS.md` and links it to
  `~/.dotfile/.claude/CLAUDE.md`.
- The previous Codex-only `AGENTS.md` was preserved under
  `backup/20260816_040832/.codex/AGENTS.md`.

### 2. Codex hooks

- Added `.codex/hooks.json`, installed as `~/.codex/hooks.json`.
- Configured `SessionStart`, `UserPromptSubmit`, `PostToolUse`, and `Stop`.
- Reused `.claude/hooks/session-load-context.sh` for Codex session context.
- Kept Confirmo on its existing Codex-specific `notify` integration instead of
  invoking the Claude-specific hook.

### 3. Cross-agent state-write fuse

- Added `.claude/hooks/track-state-write.sh` to track code edits and
  state-keeper dispatches from lifecycle events.
- Registered the tracker in both Claude Code and Codex hook configurations.
- Changed `.claude/hooks/enforce-state-write.sh` to consume the tracker state
  instead of parsing product-specific transcript formats.

### 4. Installation

- Ran `init.sh` successfully on 2026-08-16 at 04:08 local time.
- Verified these live links:
  - `~/.codex/AGENTS.md` -> `~/.dotfile/.claude/CLAUDE.md`
  - `~/.codex/hooks.json` -> `~/.dotfile/.codex/hooks.json`
  - `~/.claude/hooks` -> `~/.dotfile/.claude/hooks`

## Verification

- JSON parsing passed for `.claude/settings.json` and `.codex/hooks.json`.
- Shell syntax checks passed for `init.sh` and all hook scripts.
- `git diff --check` passed.
- Simulated hook flows confirmed:
  - normal code edits trigger the Stop fuse;
  - `.agent/state`-only edits do not trigger it;
  - a detected state-keeper dispatch suppresses the fuse;
  - Codex-shaped `SessionStart` input loads the project state index.

## Remaining work and limitations

- Restart Codex and use `/hooks` to review and trust the installed hooks.
- The old Codex-only Playwright guidance is backed up but is not present in the
  shared `CLAUDE.md`; merge it there if it should remain active.
- Codex does not load `.claude/agents/state-keeper.md`; its state-keeper agent
  definition still needs a Codex-native equivalent or an explicit dispatch
  prompt.
- Edit tracking recognizes structured edit tools and Codex `apply_patch` calls.
  Arbitrary file mutation performed inside Bash remains outside the fuse.
- The existing Codex Confirmo `notify` setting lives in local
  `~/.codex/config.toml` and is not installed by this repository.
