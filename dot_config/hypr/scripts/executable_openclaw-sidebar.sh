#!/usr/bin/env bash
# SL1C3D-L4BS — Open AI sidebar (OpenClaw gateway UI). Bind to Super+Shift+A.
set -e

base_url="http://127.0.0.1:18789/"
cfg="$HOME/.openclaw/openclaw.json"

read_token() {
  # Strict local-only secrets: never read tokens from synced dotfiles/config.
  # Prefer env var, then a machine-local secret file.
  if [ -n "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
    printf '%s' "$OPENCLAW_GATEWAY_TOKEN"
    return 0
  fi

  local token_file="$HOME/.openclaw/secrets/gateway_token"
  if [ -f "$token_file" ]; then
    # shellcheck disable=SC2002
    cat "$token_file" 2>/dev/null | tr -d '\n' || true
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
token="$(read_token)"

url="$base_url"
if [ -n "$token" ]; then
  url="${base_url}?token=${token}"
fi

xdg-open "$url" 2>/dev/null || sensible-browser "$url" 2>/dev/null || true
