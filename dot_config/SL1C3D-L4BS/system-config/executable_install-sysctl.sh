#!/usr/bin/env bash
# SL1C3D-L4BS — Install sysctl performance drop-in
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo cp "$SCRIPT_DIR/sysctl.d/99-sl1c3d-l4bs-performance.conf" /etc/sysctl.d/
sudo sysctl --system
echo "[SL1C3D-L4BS] sysctl performance tuning applied."
