#!/usr/bin/env bash
# SL1C3D-L4BS — window overview with live preview when available. Bind to Super+Tab.
# If hypr-alttab or hyprswitch is installed, use it; else fall back to list overview.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v hypr-alttab &>/dev/null; then
  exec hypr-alttab
fi
if command -v hyprswitch &>/dev/null; then
  exec hyprswitch
fi
exec "$SCRIPT_DIR/overview.sh"
