#!/usr/bin/env bash
# Start session daemons (bar, wallpaper, swaync, etc.) after Hyprland is up.
# Used from autostart.conf so bar/wallpaper come up reliably after reboot (TTY login).
set -euo pipefail
# Wait for session and systemd user to be ready (after reboot 1s can be too short)
sleep 2
# Ensure systemd user has Wayland env (Hyprland sets WAYLAND_DISPLAY; propagate to user units)
[[ -n "${WAYLAND_DISPLAY:-}" ]] && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland 2>/dev/null || true
systemctl --user start \
  quickshell.service \
  swaync.service \
  clipboard-history.service \
  swww.service \
  wallpaper-restore.service \
  hypridle.service \
  theme-propagation.service
