#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# ai-status.sh — AI status for eww bar (SL1C3dCLI + Claude + Ollama)
# Returns: JSON with class + label for the bar module
# ══════════════════════════════════════════════════════════════

STATUS_FILE="/tmp/ai-panel/status.json"

# Check if SL1C3dCLI is running
if pgrep -f "sl1c3d-cli" > /dev/null 2>&1; then
    # Check if Ollama is also up
    ollama_up=$(curl -sf http://127.0.0.1:11434/ > /dev/null 2>&1 && echo "1" || echo "0")

    if [[ -f "$STATUS_FILE" ]]; then
        status=$(python3 -c "
import json
try:
    d = json.load(open('$STATUS_FILE'))
    s = d.get('status', 'idle')
    if s == 'running':
        print('{\"class\":\"running\",\"label\":\"thinking...\",\"icon\":\"󰧑\"}')
    else:
        print('{\"class\":\"idle\",\"label\":\"SL1C3d\",\"icon\":\"󰧑\"}')
except:
    print('{\"class\":\"idle\",\"label\":\"SL1C3d\",\"icon\":\"󰧑\"}')
" 2>/dev/null)
    else
        if [[ "$ollama_up" == "1" ]]; then
            echo '{"class":"idle","label":"SL1C3d","icon":"󰧑"}'
        else
            echo '{"class":"idle","label":"SL1C3d","icon":"󰧑"}'
        fi
        exit 0
    fi
    echo "$status"
    exit 0
fi

# SL1C3dCLI not running — check daemon
if [[ -f "$STATUS_FILE" ]]; then
    status=$(python3 -c "
import json
try:
    d = json.load(open('$STATUS_FILE'))
    s = d.get('status', 'idle')
    m = d.get('model', 'claude')
    if s == 'running':
        print('{\"class\":\"running\",\"label\":\"thinking...\",\"icon\":\"󰧑\"}')
    elif s == 'error':
        print('{\"class\":\"error\",\"label\":\"error\",\"icon\":\"󰧑\"}')
    else:
        print(f'{\"class\":\"idle\",\"label\":\"{m}\",\"icon\":\"󰧑\"}')
except:
    print('{\"class\":\"off\",\"label\":\"off\",\"icon\":\"󰧑\"}')
" 2>/dev/null)
    [[ -z "$status" ]] && status='{"class":"off","label":"off","icon":"󰧑"}'
    echo "$status"
    exit 0
fi

# Check if Ollama at least is running
if curl -sf http://127.0.0.1:11434/ > /dev/null 2>&1; then
    echo '{"class":"off","label":"ready","icon":"󰧑"}'
else
    echo '{"class":"off","label":"off","icon":"󰧑"}'
fi
