#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS record-toggle — wf-recorder wrapper
# Usage: record-toggle.sh [fullscreen|region|audio|stop]
# Output: ~/Videos/Recordings/YYYYMMDD-HHMMSS.mp4
# Keybinds:
#   Super+F9        = fullscreen
#   Super+Shift+F9  = region
#   Super+Ctrl+F9   = audio
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

RECORDINGS_DIR="${HOME}/Videos/Recordings"
mkdir -p "$RECORDINGS_DIR"

is_recording() {
    pgrep -x wf-recorder > /dev/null 2>&1
}

stop_recording() {
    pkill -INT wf-recorder 2>/dev/null || true
    sleep 0.5
    notify-send --app-name="Recording" --icon=media-record "Recording stopped" \
        "Saved to ~/Videos/Recordings/" --expire-time=3000
}

start_recording() {
    local mode="${1:-fullscreen}"
    local timestamp
    timestamp="$(date +%Y%m%d-%H%M%S)"
    local output="${RECORDINGS_DIR}/${timestamp}.mp4"

    case "$mode" in
        region)
            local geom
            geom=$(slurp 2>/dev/null) || exit 0
            wf-recorder -g "$geom" -f "$output" &
            disown
            ;;
        audio)
            wf-recorder -a -f "$output" &
            disown
            ;;
        fullscreen|*)
            wf-recorder -f "$output" &
            disown
            ;;
    esac

    sleep 0.3
    notify-send --app-name="Recording" --icon=media-record \
        "Recording started" "Mode: $mode → $output" --expire-time=3000
}

MODE="${1:-fullscreen}"

if [[ "$MODE" == "stop" ]]; then
    stop_recording
    exit 0
fi

if is_recording; then
    stop_recording
else
    start_recording "$MODE"
fi
