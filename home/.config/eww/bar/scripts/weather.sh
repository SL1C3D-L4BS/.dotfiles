#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# weather.sh — Weather poller for eww bar
# Polls wttr.in every 30 minutes, caches to /tmp/weather-cache
# Outputs JSON: {"icon": "...", "temp": "...", "desc": "..."}
# ══════════════════════════════════════════════════════════════

CACHE="/tmp/weather-cache"
INTERVAL=1800  # 30 minutes

fetch_weather() {
  # Network check
  if ! ping -c1 -W2 1.1.1.1 &>/dev/null; then
    return 1
  fi

  local raw
  raw=$(curl -sf --max-time 10 'wttr.in/?format=%c|%t|%C' 2>/dev/null)
  [[ -z "$raw" ]] && return 1

  local icon temp desc
  icon=$(echo "$raw" | cut -d'|' -f1 | xargs)
  temp=$(echo "$raw" | cut -d'|' -f2 | sed 's/+//')
  desc=$(echo "$raw" | cut -d'|' -f3)

  printf '{"icon": "%s", "temp": "%s", "desc": "%s"}\n' "$icon" "$temp" "$desc" > "$CACHE"
}

output() {
  if [[ -f "$CACHE" ]]; then
    cat "$CACHE"
  else
    echo '{"icon": "", "temp": "", "desc": ""}'
  fi
}

# Initial fetch if cache is stale or missing
if [[ ! -f "$CACHE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) )) -gt $INTERVAL ]]; then
  fetch_weather
fi

output

while true; do
  sleep "$INTERVAL"
  fetch_weather
  output
done
