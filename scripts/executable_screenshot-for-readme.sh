#!/usr/bin/env bash
# SL1C3D-L4BS — capture screenshot for README. Uses grim + slurp (Wayland).
# Usage: ./screenshot-for-readme.sh [filename]
#   filename: e.g. bar.png, hub.png (default: screenshot-$(date +%Y%m%d-%H%M%S).png)
# Output: ~/assets/screenshots/ or $ASSETS_SCREENSHOTS
set -e
DIR="${ASSETS_SCREENSHOTS:-$HOME/assets/screenshots}"
mkdir -p "$DIR"
NAME="${1:-screenshot-$(date +%Y%m%d-%H%M%S).png}"
OUT="$DIR/$NAME"
if command -v slurp &>/dev/null && command -v grim &>/dev/null; then
  echo "Select region (or Cancel for full screen)..."
  if GEOM=$(slurp 2>/dev/null); then
    grim -g "$GEOM" "$OUT"
  else
    grim "$OUT"
  fi
  echo "Saved: $OUT"
else
  echo "Install grim and slurp (e.g. paru -S grim slurp)"
  exit 1
fi
