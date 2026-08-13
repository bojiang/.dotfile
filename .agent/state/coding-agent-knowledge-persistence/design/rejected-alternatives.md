# Knowledge-Persistence Design: Trade-offs and Rejected Alternatives

## Core trade-off
The Stop-hook fuse guarantees the judgment happens; it never judges content itself.
Write quality is unverifiable by script, so "forced write" is impossible in principle —
the ceiling is "forced one-time judgment".

## Rejected alternatives (each will look attractive again — don't)
- mtime-based staleness gates: create junk records; the only mechanical way to silence them is writing filler to state/.
- External cheap-model judge (haiku via `claude -p`): the main model is the only party holding full turn context.
- Main-model self-discipline via CLAUDE.md prose alone: the original failure this design replaces.

Current mechanism and file map: see [../implementation/mechanism.md](../implementation/mechanism.md).
