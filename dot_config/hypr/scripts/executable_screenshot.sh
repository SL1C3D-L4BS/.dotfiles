#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS screenshot — grim + slurp, brand-integrated
# Usage: screenshot.sh [region|full|region-copy|window]
# Output: ~/Pictures/Screenshots/YYYYMMDD-HHMMSS.png
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

DIR="${HOME}/Pictures/Screenshots"
mkdir -p "$DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="${DIR}/${STAMP}.png"
MODE="${1:-region}"

notify() {
    local msg="$1"
    if command -v notify-send &>/dev/null; then
        notify-send --app-name="Screenshot" --icon=camera-photo "$msg" --expire-time=2000
    fi
}

case "$MODE" in
    region)
        if GEOM=$(slurp 2>/dev/null); then
            grim -g "$GEOM" "$FILE"
            notify "📸 Saved: $(basename "$FILE")"
        fi
        ;;
    full)
        grim "$FILE"
        notify "📸 Full screenshot saved"
        ;;
    region-copy)
        if GEOM=$(slurp 2>/dev/null); then
            grim -g "$GEOM" - | wl-copy
            notify "📋 Region copied to clipboard"
        fi
        ;;
    window)
        WIN=$(hyprctl activewindow -j 2>/dev/null)
        if [[ -n "$WIN" ]]; then
            X=$(echo "$WIN" | python3 -c "import sys,json; d=json.load(sys.stdin)['at']; print(d[0])")
            Y=$(echo "$WIN" | python3 -c "import sys,json; d=json.load(sys.stdin)['at']; print(d[1])")
            W=$(echo "$WIN" | python3 -c "import sys,json; d=json.load(sys.stdin)['size']; print(d[0])")
            H=$(echo "$WIN" | python3 -c "import sys,json; d=json.load(sys.stdin)['size']; print(d[1])")
            grim -g "${X},${Y} ${W}x${H}" "$FILE"
            notify "📸 Window screenshot saved"
        fi
        ;;
esac
