#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# audio.sh — Output + Input audio monitor for eww
# Outputs JSON: {"icon","volume","out_name","mic_icon","mic_vol","mic_name","mic_muted"}
# ══════════════════════════════════════════════════════════════

get_audio() {
  local sink vol muted icon out_name
  local src mic_vol mic_muted mic_icon mic_name

  # ── Output (sink) ───────────────────────────────────────────
  sink=$(pactl get-default-sink 2>/dev/null)
  vol=$(pactl get-sink-volume "$sink" 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
  muted=$(pactl get-sink-mute "$sink" 2>/dev/null | grep -oP 'yes|no')
  vol=${vol:-0}

  # Short output name
  case "$sink" in
    *Wave_XLR*)    out_name="XLR" ;;
    *fifine*)      out_name="Fifine" ;;
    *pci*1f.3*)    out_name="Built-in" ;;
    *hdmi*|*pci*01.00*) out_name="HDMI" ;;
    *)             out_name="Out" ;;
  esac

  if [[ "$muted" == "yes" ]]; then
    icon="󰝟"
  elif (( vol > 66 )); then
    icon="󰕾"
  elif (( vol > 33 )); then
    icon="󰖀"
  else
    icon="󰕿"
  fi

  # ── Input (source) ─────────────────────────────────────────
  src=$(pactl get-default-source 2>/dev/null)
  mic_vol=$(pactl get-source-volume "$src" 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
  mic_muted=$(pactl get-source-mute "$src" 2>/dev/null | grep -oP 'yes|no')
  mic_vol=${mic_vol:-0}
  mic_muted=${mic_muted:-no}

  # Short input name
  case "$src" in
    *mic_chain*|*Clean*)  mic_name="DSP" ;;
    *Wave_XLR*)           mic_name="XLR" ;;
    *fifine*)             mic_name="Fifine" ;;
    *Pro_Stream*|*046d*)  mic_name="Cam" ;;
    *pci*1f.3*)           mic_name="Built-in" ;;
    *)                    mic_name="Mic" ;;
  esac

  if [[ "$mic_muted" == "yes" ]]; then
    mic_icon="󰍭"
  else
    mic_icon="󰍬"
  fi

  printf '{"icon":"%s","volume":"%s","out_name":"%s","mic_icon":"%s","mic_vol":"%s","mic_name":"%s","mic_muted":"%s"}\n' \
    "$icon" "$vol" "$out_name" "$mic_icon" "$mic_vol" "$mic_name" "$mic_muted"
}

# Initial
get_audio

# Listen for changes on both sinks and sources
pactl subscribe 2>/dev/null | while read -r line; do
  if echo "$line" | grep -qE "'change' on (sink|source)"; then
    get_audio
  fi
done
