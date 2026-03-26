#!/usr/bin/env bash
# Launch polybar — one bar per connected monitor
# Layout: HDMI-A-0 (Vizio 43") | DP-1 (ONN 24") | DP-2 (ONN 24")

pkill -x polybar 2>/dev/null
while pgrep -x polybar >/dev/null; do sleep 0.1; done

# Vizio — primary bar with tray + full modules
polybar main --config="$HOME/.config/polybar/config.ini" &

# ONN center portrait
polybar secondary --config="$HOME/.config/polybar/config.ini" &

# ONN right portrait
polybar tertiary --config="$HOME/.config/polybar/config.ini" &

echo "polybar: launched 3 bars"
