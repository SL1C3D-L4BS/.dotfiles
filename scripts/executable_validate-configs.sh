#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Validate SL1C3D-L4BS dotfile configs (Yazi, Fuzzel, Mako, Hyprland)
# Run from anywhere; requires: yazi, fuzzel, mako, python3 (tomllib)
# ─────────────────────────────────────────────────────────────────────────────

set -e
FAIL=0

echo "=== Yazi ==="
command -v yazi >/dev/null 2>&1 || { echo "  SKIP: yazi not installed"; ((FAIL++)) || true; }
if command -v yazi >/dev/null 2>&1; then
  echo "  $(yazi --version)"
  test -f ~/.config/yazi/yazi.toml && echo "  yazi.toml: present" || { echo "  yazi.toml: MISSING"; ((FAIL++)) || true; }
  test -f ~/.config/yazi/theme.toml && echo "  theme.toml: present" || { echo "  theme.toml: MISSING"; ((FAIL++)) || true; }
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import tomllib; tomllib.loads(open('$HOME/.config/yazi/yazi.toml').read())" 2>/dev/null && echo "  yazi.toml: valid TOML" || { echo "  yazi.toml: invalid TOML"; ((FAIL++)) || true; }
    python3 -c "import tomllib; tomllib.loads(open('$HOME/.config/yazi/theme.toml').read())" 2>/dev/null && echo "  theme.toml: valid TOML" || { echo "  theme.toml: invalid TOML"; ((FAIL++)) || true; }
  fi
fi

echo ""
echo "=== Fuzzel ==="
command -v fuzzel >/dev/null 2>&1 || { echo "  SKIP: fuzzel not installed"; ((FAIL++)) || true; }
if command -v fuzzel >/dev/null 2>&1; then
  echo "  $(fuzzel --version 2>/dev/null || true)"
  test -f ~/.config/fuzzel/fuzzel.ini && echo "  fuzzel.ini: present" || { echo "  fuzzel.ini: MISSING"; ((FAIL++)) || true; }
fi

echo ""
echo "=== Mako ==="
command -v mako >/dev/null 2>&1 || { echo "  SKIP: mako not installed"; ((FAIL++)) || true; }
if command -v mako >/dev/null 2>&1; then
  test -f ~/.config/mako/config && echo "  config: present" || { echo "  config: MISSING"; ((FAIL++)) || true; }
  if command -v makoctl >/dev/null 2>&1; then
    makoctl reload 2>/dev/null && echo "  makoctl reload: OK" || echo "  makoctl reload: failed (need Wayland?)"
  fi
fi

echo ""
echo "=== Hyprland (sourced files) ==="
for f in colors.conf monitors.conf env.conf programs.conf autostart.conf general.conf input.conf binds.conf windowrules.conf; do
  test -f ~/.config/hypr/$f && echo "  hypr/$f: OK" || { echo "  hypr/$f: MISSING"; ((FAIL++)) || true; }
done
grep -q 'exec-once = mako' ~/.config/hypr/autostart.conf 2>/dev/null && echo "  mako in autostart: yes" || echo "  mako in autostart: no"
grep -q 'makoctl' ~/.config/hypr/binds.conf 2>/dev/null && echo "  mako binds: yes" || echo "  mako binds: no"

echo ""
echo "=== OpenClaw (optional) ==="
command -v openclaw >/dev/null 2>&1 && echo "  openclaw: installed" || echo "  openclaw: not installed (optional)"
test -f ~/.openclaw/openclaw.json && echo "  openclaw.json: present" || echo "  openclaw.json: not found (optional)"
if command -v curl >/dev/null 2>&1; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 http://127.0.0.1:18789/ 2>/dev/null)" || code=""
  [ "$code" = "200" ] && echo "  gateway :18789: reachable" || echo "  gateway :18789: not reachable (start with: openclaw gateway start)"
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
  echo "=== Result: all checks passed ==="
  exit 0
else
  echo "=== Result: $FAIL check(s) failed ==="
  exit 1
fi
