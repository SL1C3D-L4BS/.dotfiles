#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# audio-devices.sh — Full audio state for the control panel
# Outputs JSON with output/input volumes, mute, active devices
# ══════════════════════════════════════════════════════════════

get_state() {
  local sink src
  local out_vol out_muted out_dev
  local in_vol in_muted in_dev

  # ── Output ──────────────────────────────────────────────────
  sink=$(pactl get-default-sink 2>/dev/null)
  out_vol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
  out_muted=$(pactl get-sink-mute "$sink" 2>/dev/null | grep -oP 'yes|no')
  out_vol=${out_vol:-0}
  out_muted=${out_muted:-no}

  case "$sink" in
    *Wave_XLR*)         out_dev="xlr" ;;
    *fifine*)           out_dev="fifine" ;;
    *pci*1f.3*)         out_dev="builtin" ;;
    *hdmi*|*pci*01.00*) out_dev="hdmi" ;;
    *)                  out_dev="unknown" ;;
  esac

  # ── Input ───────────────────────────────────────────────────
  src=$(pactl get-default-source 2>/dev/null)
  in_vol=$(pactl get-source-volume "$src" 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
  in_muted=$(pactl get-source-mute "$src" 2>/dev/null | grep -oP 'yes|no')
  in_vol=${in_vol:-0}
  in_muted=${in_muted:-no}

  case "$src" in
    *mic_chain*|*effect*) in_dev="dsp" ;;
    *Wave_XLR*)           in_dev="xlr" ;;
    *fifine*)             in_dev="fifine" ;;
    *Pro_Stream*|*046d*)  in_dev="cam" ;;
    *pci*1f.3*)           in_dev="builtin" ;;
    *)                    in_dev="unknown" ;;
  esac

  printf '{"out_vol":"%s","out_muted":"%s","out_dev":"%s","in_vol":"%s","in_muted":"%s","in_dev":"%s"}\n' \
    "$out_vol" "$out_muted" "$out_dev" "$in_vol" "$in_muted" "$in_dev"
}

get_state

pactl subscribe 2>/dev/null | while read -r line; do
  if echo "$line" | grep -qE "'change' on (sink|source|server)"; then
    get_state
  fi
done
