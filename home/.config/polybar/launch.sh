#!/usr/bin/env bash
# Launch polybar — one bar per connected monitor
# Layout: HDMI-A-0 (Vizio 43" landscape) | DP-1 (ONN 24" portrait) | DP-2 (ONN 24" portrait)

pkill -x polybar 2>/dev/null
sleep 0.5

# Vizio — primary bar (left, landscape) with tray
MONITOR=HDMI-A-0 polybar main --config="$HOME/.config/polybar/config.ini" &

# ONN center portrait — secondary bar (no tray)
MONITOR=DisplayPort-1 polybar secondary --config="$HOME/.config/polybar/config.ini" &

# ONN right portrait — secondary bar (no tray)
MONITOR=DisplayPort-2 polybar secondary --config="$HOME/.config/polybar/config.ini" &
