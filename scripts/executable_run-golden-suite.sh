#!/usr/bin/env bash
# SL1C3D-L4BS — Golden suite runner (lightweight)
#
# Runs the core regression gates for configs + secret boundary.

set -e

echo "=== Golden suite: validate-configs ==="
"$HOME/scripts/validate-configs.sh"

echo ""
echo "=== Golden suite: edition determinism ==="
if [ -x "$HOME/.config/SL1C3D-L4BS/bin/sl1c3d-edition" ]; then
  ed="$("$HOME/.config/SL1C3D-L4BS/bin/sl1c3d-edition" get || true)"
  echo "  edition: ${ed:-base}"
  test -f "$HOME/.config/hypr/edition.conf" && echo "  hypr/edition.conf: present" || { echo "  hypr/edition.conf: MISSING"; exit 1; }
else
  echo "  SKIP: sl1c3d-edition missing"
fi

echo ""
echo "=== Golden suite: secret audit ==="
"$HOME/scripts/audit-secrets.sh"

echo ""
echo "=== Golden suite: UI glass rules ==="
if grep -q '^layerrule = blur on, match:namespace quickshell' "$HOME/.config/hypr/layers.conf" 2>/dev/null; then
  echo "  hypr layers: quickshell blur rule present"
else
  echo "  hypr layers: quickshell blur rule MISSING"
  exit 1
fi
if grep -q '^layerrule = blur on, match:namespace ags' "$HOME/.config/hypr/layers.conf" 2>/dev/null; then
  echo "  hypr layers: AGS blur rule present"
else
  echo "  hypr layers: AGS blur rule not found (optional)"
fi

echo ""
echo "=== Golden suite: AGS doctor (optional) ==="
if [ -x "$HOME/.config/SL1C3D-L4BS/bin/sl1c3d-ags" ]; then
  "$HOME/.config/SL1C3D-L4BS/bin/sl1c3d-ags" doctor || echo "  AGS doctor: failing (likely name conflict; see docs)"
fi

echo ""
echo "=== Result: golden suite passed ==="
