# Known Gaps (audit 2026-08-13, revised 2026-08-14)

Mechanism works as documented (see mechanism.md), but these gaps are confirmed and remain true until deliberately fixed. Remove an entry when its fix lands.

## Lookup-rule violations (rule decided; code fix pending)
Authoritative rule, documented in `.claude/CLAUDE.md` line 49 as of commit 99be0fb
(2026-08-14): `.agent` is found only at `$CWD/.agent`; no component (hook or
subagent) may walk parent directories. "repo 上一级" is typical startup location,
NOT a lookup rule. `session-load-context.sh` being cwd-only is correct — do NOT
"fix" the loader to walk parents.

Two components violate the rule and await a code fix (not yet approved by user):
- `enforce-state-write.sh`: parent-walk loop (walks cwd upward to $HOME).
- `.claude/agents/state-keeper.md`: contract says "locate .agent in cwd or parents".
Effect until fixed: if a session starts inside a repo whose parent holds `.agent`,
the loader correctly loads nothing, but the fuse still fires and forces writes into
the parent `.agent`.

## Fuse blind spots (enforce-state-write.sh)
- Line 30 EDIT_TOOLS counts only Edit/Write/MultiEdit/NotebookEdit. Edits via Bash
  (sed/tee/git apply) never set `edited`.
- Subagent turns are not written into the main transcript (verified: 0 of 102
  transcripts contain isSidechain entries), so edits made inside delegated
  subagents are invisible to the fuse.

## Taxonomy usage
Only `implementation/` has ever been populated on disk; `requirements/` and
`usage/` kinds exist in the taxonomy but no docs yet.

## Misc
- init.sh (lines 24 + 50): pre-creates `$BACKUP_DIR/.claude/hooks`, so the hooks
  backup nests as `hooks/hooks`. agents/ and settings.json cases are fine.
- .claude/CLAUDE.md guide index points to `/Users/agent/workspace/mana/...`,
  which does not exist on this machine.
- .claude/settings.json model `claude-fable-5[1m]` is bypassed by the ccf alias's
  `--model` flag (zshrc.shared).
- .claude/agents/state-keeper.md frontmatter has no `model:` field — writer model
  is not pinned.
