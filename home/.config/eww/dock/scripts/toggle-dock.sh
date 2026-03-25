#!/usr/bin/env bash
STATE=$(eww get dockrev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update dockrev=false
  sleep 0.3
  eww close dock 2>/dev/null
else
  eww open dock 2>/dev/null
  eww update dockrev=true
  # Auto-close after 3 seconds
  (sleep 3 && eww update dockrev=false && sleep 0.3 && eww close dock 2>/dev/null) &
fi
