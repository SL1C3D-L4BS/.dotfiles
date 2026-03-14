#!/usr/bin/env bash
# Brightness change + swaync notification (SL1C3D-L4BS). Usage: brightness-notify.sh up|down
set -euo pipefail
case "${1:-}" in
  up)   brightnessctl -e4 -n2 set 5%+ ;;
  down) brightnessctl -e4 -n2 set 5%- ;;
  *)    echo "Usage: $0 up|down" >&2; exit 1 ;;
esac
cur="$(brightnessctl get 2>/dev/null)" || exit 0
max="$(brightnessctl max 2>/dev/null)" || exit 0
pct="$(( max > 0 ? cur * 100 / max : 0 ))"
notify-send -u low -a "Brightness" -i display-brightness -t 1200 "Brightness" "${pct}%" 2>/dev/null || true
