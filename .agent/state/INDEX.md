# State Index

Project: dotfiles repo; hosts Claude Code global config (.claude/ symlinked into ~/.claude by init.sh).

## coding-agent-knowledge-persistence
State-keeper subagent + Stop-hook fuse that persists costly-and-stable conclusions into .agent/state/.
- [design/INDEX.md](coding-agent-knowledge-persistence/design/INDEX.md) — trade-offs and rejected alternatives (do not revisit)
- [implementation/INDEX.md](coding-agent-knowledge-persistence/implementation/INDEX.md) — current mechanism, file map, and hook/agent platform gotchas hit while building it
