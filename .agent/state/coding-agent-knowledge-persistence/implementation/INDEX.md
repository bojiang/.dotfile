# coding-agent-knowledge-persistence / implementation

- [mechanism.md](mechanism.md) — how the state-keeper subagent + Stop-hook fuse works today, the state kind taxonomy ({requirements, usage, implementation} — no design/), plus the file map (hook, agent def, settings.json, confirmo guard, CLAUDE.md hook-in, init.sh symlinks)
- [gotchas.md](gotchas.md) — Claude Code hook/agent platform gotchas hit while building the mechanism: stdin-before-heredoc trap, wiring drift (verify on disk), reload semantics
- [rejected-alternatives.md](rejected-alternatives.md) — design trade-offs: why the fuse can only force a one-time judgment (not a quality write), and the three rejected alternatives — do not revisit them
- [known-gaps.md](known-gaps.md) — confirmed open gaps (2026-08-13 audit, revised 2026-08-14): lookup rule is decided and documented (CLAUDE.md L49, commit 99be0fb: `.agent` at $CWD only, no parent walk) — fuse and state-keeper contract still violate it, code fix pending; fuse blind to Bash edits and subagent edits, plus misc wiring nits
