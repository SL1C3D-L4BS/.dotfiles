#!/usr/bin/env bash
# Toggle dashboard — closes all other popups first (omarchy pattern)
STATE=$(eww get dashrev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update dashrev=false
  sleep 0.3
  eww close dash 2>/dev/null
else
  # Close all competing popups
  eww close calender media ai-panel 2>/dev/null
  eww update calrev=false musicrev=false ai_panel_rev=false 2>/dev/null
  eww open dash 2>/dev/null
  eww update dashrev=true
fi
