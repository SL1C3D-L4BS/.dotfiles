#!/usr/bin/env bash
# SL1C3D-L4BS — Open AI sidebar (OpenClaw gateway UI). Bind to Super+Shift+A.
set -e

base_url="http://127.0.0.1:18789/"
cfg="$HOME/.openclaw/openclaw.json"

read_token() {
  if command -v jq >/dev/null 2>&1; then
    jq -r '.gateway.auth.token // empty' "$cfg" 2>/dev/null || true
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$cfg" <<'PY' 2>/dev/null || true
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
print(((data.get("gateway") or {}).get("auth") or {}).get("token") or "")
PY
    return 0
  fi
  return 0
}

start_gateway() {
  if command -v systemctl >/dev/null 2>&1 && systemctl --user list-unit-files 2>/dev/null | grep -q '^openclaw-gateway\.service'; then
    systemctl --user start openclaw-gateway.service >/dev/null 2>&1 || true
    return 0
  fi
  test -x "$HOME/.openclaw/bin/openclaw" && "$HOME/.openclaw/bin/openclaw" gateway start & disown || true
}

code="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "$base_url" 2>/dev/null || true)"
if ! echo "$code" | grep -qE '^[23]'; then
  start_gateway
  sleep 2
fi

token=""
if [ -f "$cfg" ]; then
  token="$(read_token)"
fi

url="$base_url"
if [ -n "$token" ]; then
  url="${base_url}?token=${token}"
fi

xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null || true
