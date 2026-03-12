#!/usr/bin/env bash
# SL1C3D-L4BS — window/workspace overview: list clients in Fuzzel, focus on select. Bind to Super+A.
set -e
notify() {
  local msg="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "SL1C3D-L4BS" "$msg" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v makoctl >/dev/null 2>&1; then
    makoctl dismiss >/dev/null 2>&1 || true
  fi
  echo "$msg" >&2
}

if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
  notify "Overview requires hyprctl + jq."
  exit 1
fi
if ! command -v fuzzel &>/dev/null; then
  notify "Overview requires fuzzel."
  exit 1
fi

DISPLAY_FILE="$(mktemp)"
ADDR_FILE="$(mktemp)"
trap 'rm -f "$DISPLAY_FILE" "$ADDR_FILE"' EXIT

clients_json="$(hyprctl clients -j 2>&1)" || {
  notify "hyprctl clients failed (not in Hyprland session?)"
  echo "$clients_json" >&2
  exit 1
}
if [ -z "$clients_json" ]; then
  notify "No Hyprland clients returned."
  exit 0
fi

while IFS= read -r line; do
  ws="$(echo "$line" | jq -r '.workspace.name')"
  title="$(echo "$line" | jq -r '.title // .class' | head -c 50)"
  addr="$(echo "$line" | jq -r '.address')"
  echo "${ws}  ${title}" >> "$DISPLAY_FILE"
  echo "$addr" >> "$ADDR_FILE"
done < <(echo "$clients_json" | jq -c '.[]' 2>/dev/null || true)

if [ ! -s "$DISPLAY_FILE" ]; then
  notify "No windows to show in overview."
  exit 0
fi

SEL="$(fuzzel --dmenu --width 56 --lines 16 < "$DISPLAY_FILE")" || true
[ -z "$SEL" ] && exit 0
LN=1
while IFS= read -r d; do
  [ "$d" = "$SEL" ] && break
  ((LN++)) || true
done < "$DISPLAY_FILE"
ADDR="$(sed -n "${LN}p" "$ADDR_FILE")"
[ -n "$ADDR" ] && hyprctl dispatch focuswindow "address:$ADDR"
