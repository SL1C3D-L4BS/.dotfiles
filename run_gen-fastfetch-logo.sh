#!/usr/bin/env bash
# SL1C3D-L4BS — regenerate fastfetch logo PNG from SVG (chafa source of truth)
set -e
mkdir -p "$HOME/.config/fastfetch"
svg="${CHEZMOI_SOURCE_DIR}/assets/icons/Logo.svg"
if [[ -f "$svg" ]] && command -v rsvg-convert &>/dev/null; then
  rsvg-convert -w 160 -h 160 -f png "$svg" -o "$HOME/.config/fastfetch/logo.png"
fi
