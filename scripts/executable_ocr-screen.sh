#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS ocr-screen — region select → OCR text → clipboard
# Requires: tesseract, grim, slurp, wl-copy
# Keybind: Super+Shift+O
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

GEOM=$(slurp -d 2>/dev/null) || exit 0

grim -g "$GEOM" - \
  | tesseract stdin stdout \
  | wl-copy

TEXT=$(wl-paste 2>/dev/null | head -c 80 | tr '\n' ' ')
notify-send --app-name="OCR" --icon=scanner \
    "Text copied to clipboard" \
    "${TEXT}..." \
    --expire-time=3000
