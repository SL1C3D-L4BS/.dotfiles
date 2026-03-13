#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS rbw-picker — Bitwarden credential picker via Walker/stdin
# Keybind: Super+Shift+semicolon
# Requires: rbw, walker, wl-copy
# Setup: rbw config set email <your@email> && rbw login
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Ensure rbw is unlocked
if ! rbw unlocked 2>/dev/null; then
    rbw unlock
fi

# List credentials: "name [username]"
SELECTION=$(rbw list --fields id,name,user 2>/dev/null \
    | awk -F'\t' 'NF>=2 { print $2 " [" ($3 != "" ? $3 : "no user") "]" "\t" $1 }' \
    | walker --dmenu --prompt "󰌾 Password: " 2>/dev/null \
    | awk -F'\t' '{print $2}')

if [[ -z "$SELECTION" ]]; then
    exit 0
fi

# Get the password for the selected entry
PASSWORD=$(rbw get "$SELECTION" 2>/dev/null)

if [[ -n "$PASSWORD" ]]; then
    echo -n "$PASSWORD" | wl-copy
    notify-send --app-name="rbw" --icon=dialog-password \
        "Password copied" "Expires from clipboard in 45s" \
        --expire-time=3000

    # Auto-clear clipboard after 45 seconds
    (
        sleep 45
        wl-paste 2>/dev/null | grep -q "$PASSWORD" && wl-copy ""
    ) &
    disown
fi
