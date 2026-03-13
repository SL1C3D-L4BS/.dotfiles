#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS screenshot — grim + slurp + satty (annotate before save/copy)
# Usage: screenshot.sh [region|full|region-copy|window|annotate]
# Output: ~/Pictures/Screenshots/satty-YYYYMMDD-HHMMSS.png
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
        # Region select → annotate with satty → save to file
        if GEOM=$(slurp -d 2>/dev/null); then
            grim -g "$GEOM" - | satty \
                --filename - \
                --output-filename "$FILE" \
                --early-exit
            notify "Saved: $(basename "$FILE")"
        fi
        ;;
    full)
        # Fullscreen → annotate → save
        grim - | satty \
            --filename - \
            --output-filename "$FILE"
        notify "Full screenshot saved"
        ;;
    region-copy)
        # Region select → annotate → copy to clipboard (no file)
        if GEOM=$(slurp -d 2>/dev/null); then
            grim -g "$GEOM" - | satty \
                --filename - \
                --copy-command wl-copy \
                --early-exit
            notify "Region copied to clipboard"
        fi
        ;;
    window)
        # Active window → annotate → save
        WIN=$(hyprctl activewindow -j 2>/dev/null)
        if [[ -n "$WIN" ]]; then
            X=$(echo "$WIN" | jq -r '.at[0]')
            Y=$(echo "$WIN" | jq -r '.at[1]')
            W=$(echo "$WIN" | jq -r '.size[0]')
            H=$(echo "$WIN" | jq -r '.size[1]')
            grim -g "${X},${Y} ${W}x${H}" - | satty \
                --filename - \
                --output-filename "$FILE" \
                --early-exit
            notify "Window screenshot saved"
        fi
        ;;
    annotate)
        # Direct annotation mode (pick file or paste from clipboard)
        if GEOM=$(slurp -d 2>/dev/null); then
            grim -g "$GEOM" - | satty --filename -
        fi
        ;;
esac
