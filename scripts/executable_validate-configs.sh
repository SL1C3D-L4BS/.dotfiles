#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Validate SL1C3D-L4BS dotfile configs (Yazi, Fuzzel, Mako, Hyprland,
# Quickshell, AGS, Ghostty, Zellij, Fastfetch, Starship)
# Run from anywhere; requires: yazi, fuzzel, mako, python3 (tomllib)
# ─────────────────────────────────────────────────────────────────────────────

set -e
FAIL=0
PASS=0

ok()   { echo "  ✔  $1"; ((PASS++)) || true; }
fail() { echo "  ✘  $1"; ((FAIL++)) || true; }
skip() { echo "  —  $1 (SKIP: $2)"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            SL1C3D-L4BS Config Validation  2026              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Hyprland ────────────────────────────────────────────────────────────────
echo "── Hyprland ─────────────────────────────────────────────────────"
for f in colors.conf monitors.conf env.conf programs.conf autostart.conf \
          general.conf input.conf binds.conf windowrules.conf layers.conf \
          hyprlock.conf hypridle.conf; do
  test -f ~/.config/hypr/$f \
    && ok "hypr/$f" \
    || fail "hypr/$f MISSING"
done
grep -q 'rounding = 12' ~/.config/hypr/general.conf 2>/dev/null \
  && ok "rounding = 12 (brand)" \
  || fail "rounding ≠ 12 — visual gap"
grep -q 'Bibata' ~/.config/hypr/env.conf 2>/dev/null \
  && ok "cursor theme set" \
  || fail "cursor theme not set in env.conf"
grep -q 'swww-daemon' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "swww-daemon in autostart" \
  || fail "swww-daemon missing from autostart"
grep -q 'cliphist store' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "cliphist in autostart" \
  || fail "cliphist missing from autostart"
grep -q 'polkit' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "polkit agent in autostart" \
  || fail "polkit agent missing"
echo ""

# ─── Yazi ────────────────────────────────────────────────────────────────────
echo "── Yazi ─────────────────────────────────────────────────────────"
if command -v yazi &>/dev/null; then
  ok "yazi installed: $(yazi --version 2>/dev/null | head -1)"
  test -f ~/.config/yazi/yazi.toml  && ok "yazi.toml" || fail "yazi.toml MISSING"
  test -f ~/.config/yazi/theme.toml && ok "theme.toml" || fail "theme.toml MISSING"
  if command -v python3 &>/dev/null; then
    python3 -c "import tomllib; tomllib.loads(open('$HOME/.config/yazi/yazi.toml').read())" 2>/dev/null \
      && ok "yazi.toml: valid TOML" || fail "yazi.toml: invalid TOML"
    python3 -c "import tomllib; tomllib.loads(open('$HOME/.config/yazi/theme.toml').read())" 2>/dev/null \
      && ok "theme.toml: valid TOML" || fail "theme.toml: invalid TOML"
  fi
else
  fail "yazi not installed"
fi
echo ""

# ─── Fuzzel ──────────────────────────────────────────────────────────────────
echo "── Fuzzel ───────────────────────────────────────────────────────"
if command -v fuzzel &>/dev/null; then
  ok "fuzzel installed: $(fuzzel --version 2>/dev/null || true)"
  test -f ~/.config/fuzzel/fuzzel.ini && ok "fuzzel.ini" || fail "fuzzel.ini MISSING"
  grep -q 'icons-enabled = yes' ~/.config/fuzzel/fuzzel.ini 2>/dev/null \
    && ok "icons enabled" || fail "icons not enabled in fuzzel"
else
  fail "fuzzel not installed"
fi
echo ""

# ─── Mako ────────────────────────────────────────────────────────────────────
echo "── Mako ─────────────────────────────────────────────────────────"
if command -v mako &>/dev/null; then
  test -f ~/.config/mako/config && ok "mako config" || fail "mako config MISSING"
  grep -q 'box-shadow' ~/.config/mako/config 2>/dev/null \
    && ok "box-shadow configured" || fail "box-shadow missing"
  if command -v makoctl &>/dev/null; then
    makoctl reload 2>/dev/null && ok "makoctl reload: OK" \
      || skip "makoctl reload" "needs Wayland session"
  fi
else
  fail "mako not installed"
fi
echo ""

# ─── Ghostty ─────────────────────────────────────────────────────────────────
echo "── Ghostty ──────────────────────────────────────────────────────"
if command -v ghostty &>/dev/null; then
  ok "ghostty installed"
  test -f ~/.config/ghostty/config && ok "ghostty config" || fail "ghostty config MISSING"
  test -f ~/.config/ghostty/themes/sl1c3d-l4bs && ok "sl1c3d-l4bs theme" || fail "theme file MISSING"
  grep -q 'font-thicken = true' ~/.config/ghostty/config 2>/dev/null \
    && ok "font-thicken enabled" || fail "font-thicken not set"
  grep -q 'font-size = 13' ~/.config/ghostty/config 2>/dev/null \
    && ok "font-size = 13" || fail "font-size not 13"
else
  fail "ghostty not installed"
fi
echo ""

# ─── Quickshell ──────────────────────────────────────────────────────────────
echo "── Quickshell ───────────────────────────────────────────────────"
if command -v quickshell &>/dev/null; then
  ok "quickshell installed"
else
  fail "quickshell not installed"
fi
test -f ~/.config/quickshell/shell.qml && ok "shell.qml" || fail "shell.qml MISSING"
test -f ~/.config/quickshell/bar/Bar.qml && ok "Bar.qml" || fail "Bar.qml MISSING"
test -f ~/.config/quickshell/bar/BrandTheme.qml && ok "BrandTheme.qml" || fail "BrandTheme.qml MISSING"
test -f ~/.config/quickshell/bar/SystemInfo.qml && ok "SystemInfo.qml" || fail "SystemInfo.qml MISSING"
grep -q 'cpuRamContent' ~/.config/quickshell/bar/Bar.qml 2>/dev/null \
  && ok "CPU/RAM pill in bar" || fail "CPU/RAM pill missing from Bar.qml"
echo ""

# ─── AGS ─────────────────────────────────────────────────────────────────────
echo "── AGS ──────────────────────────────────────────────────────────"
if command -v ags &>/dev/null; then
  ok "ags installed: $(ags --version 2>/dev/null | head -1 || true)"
else
  fail "ags not installed"
fi
test -f ~/.config/ags/app.ts && ok "app.ts" || fail "app.ts MISSING"
test -f ~/.config/ags/widget/QuickSettings.tsx && ok "QuickSettings.tsx" || fail "QuickSettings.tsx MISSING"
test -f ~/.config/ags/style.scss && ok "style.scss" || fail "style.scss MISSING"
grep -q 'qs-panel' ~/.config/ags/style.scss 2>/dev/null \
  && ok "QS panel styles present" || fail "QS panel styles missing"
echo ""

# ─── Zellij ──────────────────────────────────────────────────────────────────
echo "── Zellij ───────────────────────────────────────────────────────"
if command -v zellij &>/dev/null; then
  ok "zellij installed: $(zellij --version 2>/dev/null)"
  test -f ~/.config/zellij/config.kdl && ok "config.kdl" || fail "config.kdl MISSING"
  grep -q 'default_mode "normal"' ~/.config/zellij/config.kdl 2>/dev/null \
    && ok "default_mode normal" || fail "default_mode not normal"
  grep -q 'compact-bar' ~/.config/zellij/layouts/default.kdl 2>/dev/null \
    && ok "compact-bar layout" || fail "compact-bar missing"
else
  fail "zellij not installed"
fi
echo ""

# ─── Starship ────────────────────────────────────────────────────────────────
echo "── Starship ─────────────────────────────────────────────────────"
if command -v starship &>/dev/null; then
  ok "starship installed: $(starship --version 2>/dev/null | head -1)"
  test -f ~/.config/starship.toml && ok "starship.toml" || fail "starship.toml MISSING"
  grep -q 'uE0B6\|\\uE0B6\|E0B6' ~/.config/starship.toml 2>/dev/null \
    && ok "powerline glyphs configured" || fail "powerline glyphs missing"
else
  fail "starship not installed"
fi
echo ""

# ─── Fastfetch ───────────────────────────────────────────────────────────────
echo "── Fastfetch ────────────────────────────────────────────────────"
if command -v fastfetch &>/dev/null; then
  ok "fastfetch installed: $(fastfetch --version 2>/dev/null | head -1)"
  test -f ~/.config/fastfetch/config.jsonc && ok "config.jsonc" || fail "config.jsonc MISSING"
else
  fail "fastfetch not installed"
fi
echo ""

# ─── OpenClaw (optional) ─────────────────────────────────────────────────────
echo "── OpenClaw (optional) ──────────────────────────────────────────"
command -v openclaw &>/dev/null && ok "openclaw installed" || skip "openclaw" "optional"
test -f ~/.openclaw/openclaw.json && ok "openclaw.json" || skip "openclaw.json" "optional"
if command -v curl &>/dev/null; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 http://127.0.0.1:18789/ 2>/dev/null)" || code=""
  [ "$code" = "200" ] && ok "gateway :18789 reachable" || skip "gateway :18789" "not running"
fi
echo ""

# ─── Result ──────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
if [ "$FAIL" -eq 0 ]; then
  echo "║  ✔  All $PASS checks passed — SL1C3D-L4BS is elite.          ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  exit 0
else
  echo "║  $FAIL check(s) failed, $PASS passed — fix above then re-run.  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  exit 1
fi
