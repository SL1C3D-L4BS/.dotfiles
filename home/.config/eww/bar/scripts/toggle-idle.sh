#!/usr/bin/env bash
# Toggle idle inhibitor (caffeine mode)
LOCKFILE="/tmp/.idle-inhibited"

if [[ -f "$LOCKFILE" ]]; then
  rm -f "$LOCKFILE"
  # Kill any running idle inhibitors
  pkill -f 'systemd-inhibit.*idle' 2>/dev/null
  pkill -f 'wayland-idle-inhibitor' 2>/dev/null
  # Re-enable xset dpms if on X11
  if [[ -n "$DISPLAY" ]]; then
    xset +dpms 2>/dev/null
    xset s on 2>/dev/null
  fi
else
  touch "$LOCKFILE"
  # Disable screen blanking
  if [[ -n "$DISPLAY" ]]; then
    xset -dpms 2>/dev/null
    xset s off 2>/dev/null
  fi
fi
