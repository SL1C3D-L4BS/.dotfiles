#!/usr/bin/env bash
STATE=$(eww get audiorev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update audiorev=false
  sleep 0.3
  eww close audio-control 2>/dev/null
else
  # Close competing popups
  eww close dash calender media ai-panel 2>/dev/null
  eww update dashrev=false calrev=false musicrev=false ai_panel_rev=false 2>/dev/null
  eww open audio-control 2>/dev/null
  eww update audiorev=true
fi
