#!/usr/bin/env bash
STATE=$(eww get calrev 2>/dev/null)
if [[ "$STATE" == "true" ]]; then
  eww update calrev=false
  sleep 0.2
  eww close calender 2>/dev/null
else
  eww close dash media 2>/dev/null
  eww update dashrev=false musicrev=false 2>/dev/null
  eww open calender 2>/dev/null
  eww update calrev=true
fi
