#!/usr/bin/env bash
# SL1C3D-L4BS — Open AI sidebar (OpenClaw gateway UI). Bind to Super+Shift+A.
set -e
URL="http://127.0.0.1:18789/"
if ! curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "$URL" 2>/dev/null | grep -qE '^[23]'; then
  command -v openclaw &>/dev/null && openclaw gateway start & disown
  sleep 2
fi
xdg-open "$URL" 2>/dev/null || sensible-browser "$URL" 2>/dev/null || true
