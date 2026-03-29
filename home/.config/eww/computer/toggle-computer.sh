#!/usr/bin/env bash
# Toggle Computer overlay — SIGUSR1 for instant show/hide
if pgrep -f "computer/main.py" > /dev/null 2>&1; then
    pkill -USR1 -f "computer/main.py"
else
    nohup "$HOME/.local/bin/computer" &>/tmp/computer-gui.log &
    disown
fi
