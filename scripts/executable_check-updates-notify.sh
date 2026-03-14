#!/usr/bin/env bash
# Notify if Arch updates are available (run from systemd user timer or cron). SL1C3D-L4BS.
set -euo pipefail
if ! command -v checkupdates &>/dev/null; then
  exit 0
fi
count="$(checkupdates 2>/dev/null | wc -l)"
if [[ "${count:-0}" -gt 0 ]]; then
  notify-send -u normal -a "Updates" -i system-software-update \
    "System updates" "${count} package(s) available. Run: paru -Syu or sudo pacman -Syu" \
    --expire-time=8000 2>/dev/null || true
fi
