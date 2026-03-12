#!/usr/bin/env bash
# SL1C3D-L4BS — Install all system configs (getty autologin, pacman, sysctl)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
chmod +x install-getty-autologin.sh install-pacman-conf.sh install-sysctl.sh
./install-getty-autologin.sh
./install-pacman-conf.sh
./install-sysctl.sh
echo "[SL1C3D-L4BS] All configs installed. Reboot for TTY autologin; consider reflector for mirrorlist."
