#!/usr/bin/env bash
# Monitor layout — the_architect | 2026
# LEFT:   Vizio D43f-J04 43"  HDMI-A-0    landscape  1920x1080 @60Hz
# CENTER: ONN 100002487  24"  DisplayPort-1  portrait   1080x1920 @75Hz
# RIGHT:  ONN 100002487  24"  DisplayPort-2  portrait   1080x1920 @75Hz

xrandr \
  --output HDMI-A-0      --mode 1920x1080 --rate 60    --pos 0x420    --rotate normal \
  --output DisplayPort-1 --mode 1920x1080 --rate 74.97 --pos 1920x0   --rotate left \
  --output DisplayPort-2 --mode 1920x1080 --rate 60    --pos 3000x0   --rotate left \
  --output DisplayPort-0 --off \
  --output DVI-D-0       --off
