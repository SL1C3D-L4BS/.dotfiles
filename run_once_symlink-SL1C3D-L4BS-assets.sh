#!/usr/bin/env bash
# SL1C3D-L4BS: create config symlinks to ~/assets (wallpapers, icons) for this machine.
# Run once per machine after chezmoi apply. Use ~/.config/SL1C3D-L4BS/wallpapers and icons.

set -e
CONFIG_DIR="${HOME}/.config/SL1C3D-L4BS"
mkdir -p "$CONFIG_DIR"
ln -sfn "${HOME}/assets/wallpapers" "${CONFIG_DIR}/wallpapers"
ln -sfn "${HOME}/assets/icons" "${CONFIG_DIR}/icons"
