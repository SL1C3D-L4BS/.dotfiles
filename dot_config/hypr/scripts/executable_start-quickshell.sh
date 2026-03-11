#!/usr/bin/env bash
# Start quickshell and restart forever if it exits (so the bar never disappears).
# Run from Hyprland exec-once so we inherit WAYLAND_DISPLAY.

while true; do
	quickshell
	sleep 2
done
