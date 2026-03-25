#!/usr/bin/env bash
STATUS=$(nmcli radio wifi 2>/dev/null)
if [[ "$STATUS" == "enabled" ]]; then
  nmcli radio wifi off
else
  nmcli radio wifi on
fi
