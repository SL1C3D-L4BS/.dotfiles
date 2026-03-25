#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# network-rate.sh — Live bandwidth rate for eww network panel
# Outputs JSON: {"rx_rate":"...", "tx_rate":"...", "rx_total":"...", "tx_total":"..."}
# ══════════════════════════════════════════════════════════════

IFACE=$(ip -o link show 2>/dev/null | awk -F': ' '/state UP/ && !/lo:/{print $2; exit}')
[[ -z "$IFACE" ]] && IFACE="enp0s31f6"

human_rate() {
  local bps=$1
  if (( bps >= 1048576 )); then
    printf "%d.%d MB/s" $(( bps / 1048576 )) $(( (bps % 1048576) * 10 / 1048576 ))
  elif (( bps >= 1024 )); then
    printf "%d KB/s" $(( bps / 1024 ))
  else
    printf "%d B/s" "$bps"
  fi
}

human_total() {
  local bytes=$1
  if (( bytes >= 1073741824 )); then
    printf "%d.%02d GB" $(( bytes / 1073741824 )) $(( (bytes % 1073741824) * 100 / 1073741824 ))
  elif (( bytes >= 1048576 )); then
    printf "%d.%d MB" $(( bytes / 1048576 )) $(( (bytes % 1048576) * 10 / 1048576 ))
  else
    printf "%d KB" $(( bytes / 1024 ))
  fi
}

prev_rx=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
prev_tx=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

while true; do
  sleep 2
  cur_rx=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
  cur_tx=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)

  rx_diff=$(( (cur_rx - prev_rx) / 2 ))
  tx_diff=$(( (cur_tx - prev_tx) / 2 ))
  (( rx_diff < 0 )) && rx_diff=0
  (( tx_diff < 0 )) && tx_diff=0

  rx_rate=$(human_rate "$rx_diff")
  tx_rate=$(human_rate "$tx_diff")
  rx_total=$(human_total "$cur_rx")
  tx_total=$(human_total "$cur_tx")

  printf '{"rx_rate":"%s","tx_rate":"%s","rx_total":"%s","tx_total":"%s"}\n' \
    "$rx_rate" "$tx_rate" "$rx_total" "$tx_total"

  prev_rx=$cur_rx
  prev_tx=$cur_tx
done
