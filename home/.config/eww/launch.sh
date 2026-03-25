#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# eww launch.sh — Kill existing and launch bars for all monitors
# ══════════════════════════════════════════════════════════════
set -euo pipefail

# Kill existing eww daemon gracefully
eww kill 2>/dev/null || true
sleep 0.5

# Ensure no zombie eww processes remain
pkill -x eww 2>/dev/null || true
sleep 0.2

# Create ai-panel runtime dir if missing
mkdir -p /tmp/ai-panel

# Start daemon
eww daemon &
sleep 1

# Open bars — sequential to avoid GTK race conditions
eww open bar          2>/dev/null || echo "eww: WARN failed to open bar"
sleep 0.2
eww open bar-secondary 2>/dev/null || echo "eww: WARN failed to open bar-secondary"
sleep 0.2
eww open bar-tertiary  2>/dev/null || echo "eww: WARN failed to open bar-tertiary"

echo "eww: launched 3 bars"
