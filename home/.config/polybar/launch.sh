#!/usr/bin/env bash
# Launch polybar — kills existing instances, then starts one per monitor

pkill -x polybar 2>/dev/null
sleep 0.5

if command -v xrandr &>/dev/null; then
    for m in $(xrandr --query | grep ' connected' | awk '{print $1}'); do
        MONITOR="$m" polybar main --config="$HOME/.config/polybar/config.ini" &
    done
else
    polybar main --config="$HOME/.config/polybar/config.ini" &
fi
