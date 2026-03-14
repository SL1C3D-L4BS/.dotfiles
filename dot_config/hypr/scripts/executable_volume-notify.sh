#!/usr/bin/env bash
# Volume change + swaync notification (SL1C3D-L4BS). Usage: volume-notify.sh up|down|mute
set -euo pipefail
SINK="@DEFAULT_AUDIO_SINK@"
case "${1:-}" in
  up)   wpctl set-volume -l 1 "$SINK" 5%+ ;;
  down) wpctl set-volume "$SINK" 5%- ;;
  mute) wpctl set-mute "$SINK" toggle ;;
  *)    echo "Usage: $0 up|down|mute" >&2; exit 1 ;;
esac
# Read back and notify (low priority, auto-dismiss)
vol="$(wpctl get-volume "$SINK" 2>/dev/null || true)"
[[ -n "$vol" ]] && notify-send -u low -a "Volume" -i audio-volume-high -t 1200 "Volume" "$vol" 2>/dev/null || true
