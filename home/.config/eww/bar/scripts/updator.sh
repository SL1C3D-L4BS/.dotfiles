#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# updator.sh — Arch update checker for eww
# Outputs JSON: {"icon": "...", "count": "...", "tooltip": "..."}
# ══════════════════════════════════════════════════════════════

check_updates() {
  local official=0 aur=0 total tooltip

  official=$(checkupdates 2>/dev/null | wc -l)
  aur=$(yay -Qua 2>/dev/null | wc -l)
  total=$((official + aur))

  if (( total > 0 )); then
    tooltip="Official: $official | AUR: $aur"
  else
    tooltip="System up to date"
  fi

  printf '{"icon": "󰏔", "count": "%d", "tooltip": "%s"}\n' "$total" "$tooltip"
}

while true; do
  check_updates
  sleep 600
done
