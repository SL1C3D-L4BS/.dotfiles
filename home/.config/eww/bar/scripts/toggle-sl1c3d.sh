#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# toggle-sl1c3d.sh — toggle SL1C3dCLI via SIGUSR1
# ══════════════════════════════════════════════════════════════

PID_FILE="/tmp/sl1c3d-cli.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill -USR1 "$PID"
        exit 0
    fi
fi

# Not running — launch
nohup sl1c3d-cli --no-sandbox &>/tmp/sl1c3d-cli.log &
