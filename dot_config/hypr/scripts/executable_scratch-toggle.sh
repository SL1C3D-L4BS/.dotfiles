#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS scratch-toggle — on-demand floating scratchpad launcher
# Usage: scratch-toggle.sh <ws-name> <window-class> <command>
# First call: spawns the app in the special workspace.
# Subsequent calls: toggles visibility.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

WS="$1"
CLASS="$2"
shift 2
CMD="$*"

RUNNING=$(hyprctl clients -j 2>/dev/null | python3 -c "
import sys, json
clients = json.load(sys.stdin)
for c in clients:
    if c.get('class', '') == '$CLASS':
        print('yes')
        break
" 2>/dev/null)

if [[ -z "$RUNNING" ]]; then
    hyprctl dispatch exec "[workspace special:$WS silent] $CMD"
else
    hyprctl dispatch togglespecialworkspace "$WS"
fi
