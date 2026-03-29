#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# operator-status.sh — Read Operator Core status for eww bar
# ══════════════════════════════════════════════════════════════
STATUS_FILE="/tmp/operator-core/status.json"

if [[ -f "$STATUS_FILE" ]]; then
    cat "$STATUS_FILE"
else
    echo '{"events":0,"opportunities":0,"proposals":0,"pending_actions":0,"pipeline_usd":0,"status":"offline"}'
fi
