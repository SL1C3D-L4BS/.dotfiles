#!/usr/bin/env bash
# SL1C3D-L4BS — window/workspace overview: list clients in Fuzzel, focus on select. Bind to Super+A.
set -e
if ! command -v hyprctl &>/dev/null || ! command -v jq &>/dev/null; then
  echo "hyprctl and jq required for overview"
  exit 1
fi
DISPLAY_FILE="$(mktemp)"
ADDR_FILE="$(mktemp)"
trap 'rm -f "$DISPLAY_FILE" "$ADDR_FILE"' EXIT
while IFS= read -r line; do
  ws="$(echo "$line" | jq -r '.workspace.name')"
  title="$(echo "$line" | jq -r '.title // .class' | head -c 50)"
  addr="$(echo "$line" | jq -r '.address')"
  echo "${ws}  ${title}" >> "$DISPLAY_FILE"
  echo "$addr" >> "$ADDR_FILE"
done < <(hyprctl clients -j 2>/dev/null | jq -c '.[]')
[ ! -s "$DISPLAY_FILE" ] && exit 0
SEL="$(fuzzel --dmenu --no-fuzzy-match --width 56 --lines 16 < "$DISPLAY_FILE" 2>/dev/null)" || true
[ -z "$SEL" ] && exit 0
LN=1
while IFS= read -r d; do
  [ "$d" = "$SEL" ] && break
  ((LN++)) || true
done < "$DISPLAY_FILE"
ADDR="$(sed -n "${LN}p" "$ADDR_FILE")"
[ -n "$ADDR" ] && hyprctl dispatch focuswindow "address:$ADDR"
