# 001 — SessionStart Hook & State Index Rules

Date: 2026-08-09

## Summary
Set up Claude Code SessionStart hook to auto-load project context, and defined state index governance rules.

## Changes made

### 1. SessionStart hook (global)
- Moved hook from philia093 project-level to global `~/.claude/hooks/session-load-context.sh` (symlinked from `~/.dotfile/.claude/hooks/`)
- Added hook entry to global `~/.claude/settings.json` SessionStart (alongside confirmo hook)
- Updated `~/.dotfile/init.sh` to backup + symlink `.claude/hooks` directory
- Removed project-level `.claude/settings.json` and `.claude/hooks/` from philia093

### 2. `.agent/state/INDEX.md` (philia093)
- Created project state top-level index
- Added deployment note: Hermes Home is `.run/` (not default `~/.hermes`)

### 3. Global CLAUDE.md (`~/.dotfile/.claude/CLAUDE.md`)
- Added `state/INDEX.md` to directory convention with 3 governance rules:
  1. Keep short, prefer references; only inline high-frequency info
  2. Only record non-obvious/special info
  3. Every file under `state/` must be reachable from INDEX.md directly or via sub-index
- Added emotion-awareness rule: when user shows surprise/unexpectedness, or provides info that should have been known from `.agent/`, proactively read state index and consider updating records

## Decisions
- State index loads at session start only (not per-message) — sufficient for cold-start context
- Emotion-awareness implemented as CLAUDE.md rule (not hook) — Claude's comprehension > keyword matching
- `state/INDEX.md` is a top-level index; sub-indexes (`implementation/INDEX.md`, `requirements/INDEX.md`) exist but are not auto-loaded — referenced from top index on demand
