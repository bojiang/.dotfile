# Claude Code Hook / Agent Gotchas

## stdin + heredoc (silent total failure)
Hook scripts reading hook JSON from stdin must capture stdin BEFORE any heredoc:
`INPUT=$(cat -)` then pass via argv. With `python3 - <<'EOF'`, the heredoc becomes
python's stdin and the hook input is silently lost — the hook never fires and
nothing errors. Cost a full test round to find.
Applied in: .claude/hooks/enforce-state-write.sh, .claude/hooks/session-load-context.sh.

## Wiring drift: verify on disk, not from records
Hook registration in ~/.claude/settings.json and the ~/.claude/hooks symlink can
silently drift from what backlog records claim (backlog 001 recorded wiring that
was absent on this machine). Always verify the actual files/symlinks.
Root cause now addressed: settings.json is version-managed in the repo and
symlinked into ~/.claude by init.sh — but keep verifying on disk.

## Reload semantics
- settings.json hook changes take effect immediately in the running session.
- New agent definitions under ~/.claude/agents do NOT — the agent registry loads
  at session start; restart the session to pick them up.
