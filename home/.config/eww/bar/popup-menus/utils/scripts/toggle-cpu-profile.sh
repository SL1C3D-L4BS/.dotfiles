#!/usr/bin/env bash
# Usage: toggle-cpu-profile.sh [schedutil|powersave|performance]
GOVERNOR="${1:-schedutil}"

if command -v cpupower &>/dev/null; then
  sudo cpupower frequency-set -g "$GOVERNOR" 2>/dev/null
else
  for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "$GOVERNOR" | sudo tee "$cpu" >/dev/null 2>&1
  done
fi
