#!/usr/bin/env bash
# confirmo is a machine-optional tool; settings.json is shared across machines,
# so this guard no-ops where it is not installed instead of erroring per hook event.
HOOK="$HOME/.confirmo/hooks/confirmo-hook.js"
[ -f "$HOOK" ] || exit 0
NODE=$(command -v node) || exit 0
exec "$NODE" "$HOOK"
