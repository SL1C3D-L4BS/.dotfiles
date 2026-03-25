#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# cava.sh — Audio visualizer for eww bar (hides when silent)
# ══════════════════════════════════════════════════════════════

CAVA_CFG=$(mktemp)
cat > "$CAVA_CFG" <<EOF
[general]
bars = 8
framerate = 30
sensitivity = 120

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[smoothing]
noise_reduction = 77
EOF

trap "rm -f $CAVA_CFG" EXIT

cava -p "$CAVA_CFG" 2>/dev/null | while IFS= read -r line; do
  # Replace digits with block chars, semicolons with nothing
  bar=$(echo "$line" | sed 's/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;s/;//g')
  # Only output if there's actual activity (not all ▁)
  if [[ "$bar" =~ [▂▃▄▅▆▇█] ]]; then
    echo "$bar"
  else
    echo ""
  fi
done
