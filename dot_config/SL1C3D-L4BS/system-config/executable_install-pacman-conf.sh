#!/usr/bin/env bash
# SL1C3D-L4BS — Install optimized pacman.conf (backup existing)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACMAN_CONF="/etc/pacman.conf"
if [[ -f "$PACMAN_CONF" ]]; then
  sudo cp -a "$PACMAN_CONF" "${PACMAN_CONF}.bak.$(date +%Y%m%d%H%M%S)"
fi
sudo cp "$SCRIPT_DIR/pacman.conf" "$PACMAN_CONF"
echo "[SL1C3D-L4BS] pacman.conf installed (Color, ILoveCandy, ParallelDownloads=10, VerbosePkgLists)."
