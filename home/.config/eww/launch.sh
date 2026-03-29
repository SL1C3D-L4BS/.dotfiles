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

# Create runtime dirs and seed status files for AI widgets
mkdir -p /tmp/ai-panel /tmp/computer
[[ -f /tmp/computer/status.json ]] || echo '{"state":"offline","model":"mistral","session":"","messages":0,"voice":false,"crk_step":0,"crk_step_name":"","intent_class":"","mode":"PERSONAL","risk_class":"LOW","attention_load":0.0,"open_loops":0,"trust_health":"healthy","devices_online":0,"device_count":0}' > /tmp/computer/status.json
[[ -f /tmp/computer/trust.json ]] || echo '{"health":"healthy","score":1.0}' > /tmp/computer/trust.json

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
