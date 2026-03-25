#!/usr/bin/env bash
STATE=$(eww get netrev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update netrev=false
  sleep 0.3
  eww close net-panel 2>/dev/null
else
  eww close dash calender media ai-panel audio-control 2>/dev/null
  eww update dashrev=false calrev=false musicrev=false ai_panel_rev=false audiorev=false 2>/dev/null
  eww open net-panel 2>/dev/null
  eww update netrev=true
fi
