#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# network.sh — Network monitor for eww (systemd-networkd)
# Works without NetworkManager — uses ip/networkctl/systemd-resolve
# Outputs JSON on change: icon, status, name, ip, iface, rx, tx, gateway
# ══════════════════════════════════════════════════════════════

IFACE=""
PREV=""

# Find the first UP non-loopback interface
find_iface() {
  ip -o link show 2>/dev/null | awk -F': ' '/state UP/ && !/lo:/{print $2; exit}'
}

human_bytes() {
  local bytes=$1
  if (( bytes >= 1073741824 )); then
    printf "%d.%dG" $(( bytes / 1073741824 )) $(( (bytes % 1073741824) * 10 / 1073741824 ))
  elif (( bytes >= 1048576 )); then
    printf "%d.%dM" $(( bytes / 1048576 )) $(( (bytes % 1048576) * 10 / 1048576 ))
  elif (( bytes >= 1024 )); then
    printf "%dK" $(( bytes / 1024 ))
  else
    printf "%dB" "$bytes"
  fi
}

get_network() {
  local icon status name ip_addr gw rx tx rx_h tx_h iface_type

  IFACE=$(find_iface)

  if [[ -z "$IFACE" ]]; then
    echo '{"icon":"󰖪","status":"Off","name":"Disconnected","ip":"--","iface":"--","rx":"--","tx":"--","gateway":"--"}'
    return
  fi

  # Determine type
  if [[ "$IFACE" == enp* || "$IFACE" == eth* ]]; then
    iface_type="wired"
    icon="󰈀"
  elif [[ "$IFACE" == wl* ]]; then
    iface_type="wifi"
    icon="󰖩"
  else
    iface_type="other"
    icon="󰛳"
  fi

  # IP address
  ip_addr=$(ip -4 addr show "$IFACE" 2>/dev/null | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
  [[ -z "$ip_addr" ]] && ip_addr="--"

  # Gateway
  gw=$(ip route show default dev "$IFACE" 2>/dev/null | awk '{print $3}' | head -1)
  [[ -z "$gw" ]] && gw="--"

  # Traffic counters
  rx=$(cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
  tx=$(cat "/sys/class/net/$IFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
  rx_h=$(human_bytes "$rx")
  tx_h=$(human_bytes "$tx")

  # Connection status
  local operstate
  operstate=$(cat "/sys/class/net/$IFACE/operstate" 2>/dev/null || echo "down")
  if [[ "$operstate" == "up" && "$ip_addr" != "--" ]]; then
    status="$ip_addr"
    name="$IFACE"
  elif [[ "$operstate" == "up" ]]; then
    status="No IP"
    name="$IFACE"
    icon="󰈂"
  else
    status="Down"
    name="$IFACE"
    icon="󰖪"
  fi

  printf '{"icon":"%s","status":"%s","name":"%s","ip":"%s","iface":"%s","rx":"%s","tx":"%s","gateway":"%s"}\n' \
    "$icon" "$status" "$name" "$ip_addr" "$IFACE" "$rx_h" "$tx_h" "$gw"
}

# Initial output
get_network

# Poll every 5s (ip monitor is unreliable for all events)
while true; do
  sleep 5
  NEW=$(get_network)
  if [[ "$NEW" != "$PREV" ]]; then
    echo "$NEW"
    PREV="$NEW"
  fi
done
