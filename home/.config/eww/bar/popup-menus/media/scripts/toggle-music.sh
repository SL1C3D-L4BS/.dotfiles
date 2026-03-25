#!/usr/bin/env bash
STATE=$(eww get musicrev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update musicrev=false
  sleep 0.2
  eww close media 2>/dev/null
else
  eww close dash calender 2>/dev/null
  eww update dashrev=false calrev=false 2>/dev/null
  eww open media 2>/dev/null
  eww update musicrev=true
fi
