#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS power menu — Fuzzel-based, brand-styled
# Options: Lock | Suspend | Logout | Reboot | Shutdown
# ─────────────────────────────────────────────────────────────────────────────

choice=$(printf ' Lock\n⏾ Suspend\n󰗽 Logout\n󰑓 Reboot\n⏻ Shutdown' \
    | fuzzel \
        --dmenu \
        --lines=5 \
        --width=22 \
        --prompt="Power  " \
        --anchor=center \
    2>/dev/null)

case "$choice" in
    *Lock*)     loginctl lock-session ;;
    *Suspend*)  systemctl suspend ;;
    *Logout*)   hyprctl dispatch exit ;;
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
