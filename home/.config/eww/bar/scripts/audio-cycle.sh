#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# audio-cycle.sh — Cycle between audio devices
# Usage: audio-cycle.sh sink|source
# ══════════════════════════════════════════════════════════════
set -euo pipefail

TYPE="${1:-sink}"

if [[ "$TYPE" == "sink" ]]; then
  # Get all sinks, find current, move to next
  mapfile -t sinks < <(pactl list short sinks 2>/dev/null | awk '{print $2}')
  current=$(pactl get-default-sink 2>/dev/null)

  idx=0
  for i in "${!sinks[@]}"; do
    [[ "${sinks[$i]}" == "$current" ]] && idx=$i
  done

  next_idx=$(( (idx + 1) % ${#sinks[@]} ))
  next="${sinks[$next_idx]}"

  pactl set-default-sink "$next"
  # Move all playing streams to new sink
  pactl list short sink-inputs 2>/dev/null | awk '{print $1}' | while read -r id; do
    pactl move-sink-input "$id" "$next" 2>/dev/null || true
  done

elif [[ "$TYPE" == "source" ]]; then
  # Get all real sources (not monitors)
  mapfile -t sources < <(pactl list short sources 2>/dev/null | grep -v '\.monitor' | awk '{print $2}')
  current=$(pactl get-default-source 2>/dev/null)

  idx=0
  for i in "${!sources[@]}"; do
    [[ "${sources[$i]}" == "$current" ]] && idx=$i
  done

  next_idx=$(( (idx + 1) % ${#sources[@]} ))
  next="${sources[$next_idx]}"

  pactl set-default-source "$next"
  # Move all recording streams to new source
  pactl list short source-outputs 2>/dev/null | awk '{print $1}' | while read -r id; do
    pactl move-source-output "$id" "$next" 2>/dev/null || true
  done
fi
