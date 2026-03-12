#!/usr/bin/env bash
# SL1C3D-L4BS — Install TTY1 autologin for user the_architect
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DROPDIR="/etc/systemd/system/getty@tty1.service.d"
echo "[SL1C3D-L4BS] Installing TTY1 autologin..."
sudo mkdir -p "$DROPDIR"
sudo cp "$SCRIPT_DIR/getty@tty1.service.d/autologin.conf" "$DROPDIR/autologin.conf"
sudo systemctl daemon-reload
echo "[SL1C3D-L4BS] Done. the_architect will autologin on tty1. Reboot to test."
