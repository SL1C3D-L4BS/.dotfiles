#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Validate SL1C3D-L4BS dotfile configs — 2026 Masterclass Stack
# Tools: Hyprland, swaync, satty, kanshi, matugen, Quickshell,
#        Neovim, Zellij, Ghostty, Starship, atuin, age, restic, bluez, rbw...
# Run from anywhere; no sudo needed.
# ─────────────────────────────────────────────────────────────────────────────

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

# ─── Systemd user units (Phase 6 session daemons) ────────────────────────────
echo "── Systemd user units (Phase 6) ─────────────────────────────────"
for u in quickshell swaync clipboard-history swww wallpaper-restore hypridle theme-propagation; do
  if test -f ~/.config/systemd/user/${u}.service; then
    if systemctl --user is-enabled "${u}.service" &>/dev/null; then
      ok "${u}.service (enabled)"
    else
      ok "${u}.service (present; enable: systemctl --user enable ${u}.service)"
    fi
  else
    fail "${u}.service MISSING (chezmoi apply needed)"
  fi
done
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
# Phase 6: durable daemons run as systemd user units; autostart is minimal glue only
grep -q 'hyprpolkitagent' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "hyprpolkitagent in autostart" \
  || fail "hyprpolkitagent missing from autostart (replace polkit-gnome)"
# swww/cliphist/swaync: Phase 6 (systemd units) takes precedence over legacy autostart
if test -f ~/.config/systemd/user/quickshell.service && test -f ~/.config/systemd/user/swww.service; then
  ok "session daemons as systemd user units (Phase 6)"
elif grep -q 'swww-daemon\|swaync\|cliphist store' ~/.config/hypr/autostart.conf 2>/dev/null; then
  ok "session daemons in autostart (legacy)"
else
  fail "session daemons: need either autostart or systemd user units (quickshell.service, swww.service, etc.)"
fi
grep -q 'hyprsunset' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "hyprsunset in autostart" \
  || skip "hyprsunset autostart" "optional"
grep -q 'dbus-update-activation-environment' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "XDG portal env exported" \
  || fail "dbus-update-activation-environment missing from autostart"
grep -q 'fuzzel' ~/.config/hypr/programs.conf 2>/dev/null \
  && ok "programs.conf: \$menu = fuzzel" \
  || fail "programs.conf: \$menu not set to fuzzel"
grep -q 'swaync-client' ~/.config/hypr/binds.conf 2>/dev/null \
  && ok "swaync-client binds present" \
  || fail "swaync-client binds missing"
grep -q 'hyprsunset -t' ~/.config/hypr/binds.conf 2>/dev/null \
  && ok "hyprsunset keybinds correct (-t flag)" \
  || fail "hyprsunset keybinds incorrect (should use -t, not hyprctl hyprsunset)"
grep -q 'hyprpicker' ~/.config/hypr/binds.conf 2>/dev/null \
  && ok "hyprpicker bind present" \
  || fail "hyprpicker bind missing"
grep -q 'wf-recorder\|record-toggle' ~/.config/hypr/binds.conf 2>/dev/null \
  && ok "wf-recorder bind present" \
  || fail "wf-recorder bind missing"
skip "launcher layer (Fuzzel)" "runtime only"
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

# ─── Fuzzel (launcher — thin minimal search bar) ───────────────────────────────
echo "── Fuzzel ───────────────────────────────────────────────────────"
if command -v fuzzel &>/dev/null; then
  ok "fuzzel installed: $(fuzzel --version 2>/dev/null | head -1 || echo 'ok')"
  test -f ~/.config/fuzzel/fuzzel.ini && ok "fuzzel.ini" || fail "fuzzel.ini MISSING"
else
  fail "fuzzel not installed — run: sudo pacman -S fuzzel"
fi
echo ""

# ─── swaync (replaces Mako) ───────────────────────────────────────────────────
echo "── swaync ───────────────────────────────────────────────────────"
if command -v swaync &>/dev/null; then
  ok "swaync installed: $(swaync --version 2>/dev/null | head -1 || echo 'ok')"
  test -f ~/.config/swaync/config.json && ok "config.json" || fail "config.json MISSING (chezmoi apply needed)"
  test -f ~/.config/swaync/style.css   && ok "style.css"   || fail "style.css MISSING (chezmoi apply needed)"
  if test -f ~/.config/swaync/config.json; then
    python3 -c "import json; json.load(open('$HOME/.config/swaync/config.json'))" 2>/dev/null \
      && ok "config.json: valid JSON" || fail "config.json: invalid JSON"
  fi
else
  fail "swaync not installed — run: sudo pacman -S swaync"
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
test -f ~/.config/quickshell/shell.qml       && ok "shell.qml"       || fail "shell.qml MISSING"
test -f ~/.config/quickshell/bar/Bar.qml     && ok "Bar.qml"         || fail "Bar.qml MISSING"
test -f ~/.config/quickshell/bar/BrandTheme.qml && ok "BrandTheme.qml" || fail "BrandTheme.qml MISSING"
test -f ~/.config/quickshell/bar/SystemInfo.qml && ok "SystemInfo.qml" || fail "SystemInfo.qml MISSING"
test -f ~/.config/quickshell/bar/AIPanel.qml    && ok "AIPanel.qml (AI sidebar)" || fail "AIPanel.qml MISSING (chezmoi apply needed)"
test -f ~/.config/quickshell/bar/BluetoothWidget.qml && ok "BluetoothWidget.qml" || fail "BluetoothWidget.qml MISSING (chezmoi apply needed)"
grep -q 'cpuRamContent\|cpu\|CPU' ~/.config/quickshell/bar/Bar.qml 2>/dev/null \
  && ok "CPU/RAM pill in bar" || fail "CPU/RAM pill missing from Bar.qml"
grep -q 'aiPanelOpen' ~/.config/quickshell/bar/Bar.qml 2>/dev/null \
  && ok "AI panel toggle in Bar.qml" || fail "AI panel toggle missing (chezmoi apply needed)"
grep -q 'swaync-client' ~/.config/quickshell/bar/Bar.qml 2>/dev/null \
  && ok "swaync count poll in Bar.qml" || fail "swaync count poll missing (chezmoi apply needed)"
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
test -f ~/.config/ags/sl1c3d-tokens.scss && ok "sl1c3d-tokens.scss (Fullstack 1-4)" || fail "sl1c3d-tokens.scss MISSING"
grep -q 'surfaceGlass\|motionFastMs' ~/.config/quickshell/bar/BrandTheme.qml 2>/dev/null \
  && ok "BrandTheme.qml: glass/motion tokens (Fullstack 1-4)" \
  || fail "BrandTheme.qml: surfaceGlass/motionFastMs missing"
grep -q 'qs-panel' ~/.config/ags/style.scss 2>/dev/null \
  && ok "QS panel styles present" || fail "QS panel styles missing"
echo ""

# ─── Zellij ──────────────────────────────────────────────────────────────────
echo "── Zellij ───────────────────────────────────────────────────────"
if command -v zellij &>/dev/null; then
  ok "zellij installed: $(zellij --version 2>/dev/null)"
  test -f ~/.config/zellij/config.kdl && ok "config.kdl" || fail "config.kdl MISSING"
  test -f ~/.config/zellij/layouts/ide.kdl && ok "ide.kdl layout" || fail "ide.kdl MISSING (chezmoi apply needed)"
  test -f ~/.config/zellij/layouts/dev.kdl && ok "dev.kdl layout" || fail "dev.kdl MISSING"
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

# ─── Matugen ─────────────────────────────────────────────────────────────────
echo "── Matugen ──────────────────────────────────────────────────────"
if command -v matugen &>/dev/null; then
  ok "matugen installed: $(matugen --version 2>/dev/null | head -1 || echo 'ok')"
  test -f ~/.config/matugen/config.toml && ok "config.toml" || fail "config.toml MISSING (chezmoi apply needed)"
  test -d ~/.config/matugen/templates   && ok "templates dir" || fail "templates dir MISSING (chezmoi apply needed)"
  test -f ~/.config/matugen/post-hook.sh && ok "post-hook.sh" || fail "post-hook.sh MISSING (chezmoi apply needed)"
  for tpl in ghostty hypr-colors hyprlock swaync starship zellij yazi btop quickshell fzf cava; do
    test -f ~/.config/matugen/templates/${tpl}.template \
      && ok "template: ${tpl}" \
      || fail "template MISSING: ${tpl}.template (chezmoi apply needed)"
  done
else
  fail "matugen not installed — run: paru -S matugen-bin"
fi
echo ""

# ─── satty ───────────────────────────────────────────────────────────────────
echo "── satty ────────────────────────────────────────────────────────"
if command -v satty &>/dev/null; then
  ok "satty installed: $(satty --version 2>/dev/null | head -1 || echo 'ok')"
  test -f ~/.config/satty/config.toml && ok "config.toml" || fail "config.toml MISSING (chezmoi apply needed)"
else
  fail "satty not installed — run: sudo pacman -S satty"
fi
echo ""

# ─── kanshi ──────────────────────────────────────────────────────────────────
echo "── kanshi ───────────────────────────────────────────────────────"
if command -v kanshi &>/dev/null; then
  ok "kanshi installed: $(kanshi --version 2>/dev/null | head -1 || echo 'ok')"
  test -f ~/.config/kanshi/config && ok "kanshi config" || fail "kanshi config MISSING (chezmoi apply needed)"
else
  fail "kanshi not installed — run: sudo pacman -S kanshi"
fi
echo ""

# ─── hyprsunset ──────────────────────────────────────────────────────────────
echo "── hyprsunset ───────────────────────────────────────────────────"
if command -v hyprsunset &>/dev/null; then
  ok "hyprsunset installed: $(hyprsunset --version 2>/dev/null | head -1)"
  grep -q 'hyprsunset -t' ~/.config/hypr/binds.conf 2>/dev/null \
    && ok "binds.conf: correct -t syntax" \
    || fail "binds.conf: incorrect hyprsunset syntax (use -t, not hyprctl hyprsunset)"
else
  fail "hyprsunset not installed — run: sudo pacman -S hyprsunset"
fi
echo ""

# ─── Security / Polkit / Keyring ─────────────────────────────────────────────
echo "── Security ─────────────────────────────────────────────────────"
command -v hyprpolkitagent &>/dev/null && ok "hyprpolkitagent installed" \
  || skip "hyprpolkitagent" "AUR install needed: paru -S hyprpolkitagent"
command -v hyprpicker &>/dev/null && ok "hyprpicker installed" \
  || fail "hyprpicker MISSING — run: sudo pacman -S hyprpicker"
command -v rbw &>/dev/null && ok "rbw installed" \
  || skip "rbw" "optional (sudo pacman -S rbw)"
command -v gnome-keyring-daemon &>/dev/null && ok "gnome-keyring installed" \
  || fail "gnome-keyring MISSING — run: sudo pacman -S gnome-keyring"
grep -q 'gnome-keyring-daemon' ~/.config/hypr/autostart.conf 2>/dev/null \
  && ok "gnome-keyring in autostart" \
  || fail "gnome-keyring missing from autostart"
test -f ~/scripts/rbw-picker.sh && ok "rbw-picker.sh" \
  || skip "rbw-picker.sh" "chezmoi apply needed"
echo ""

# ─── age encryption ──────────────────────────────────────────────────────────
echo "── age ──────────────────────────────────────────────────────────"
if command -v age &>/dev/null; then
  ok "age installed: $(age --version 2>/dev/null | head -1)"
  test -f ~/.age/key.txt && ok "~/.age/key.txt exists" \
    || skip "~/.age/key.txt" "generate: age-keygen -o ~/.age/key.txt"
else
  fail "age not installed — run: sudo pacman -S age"
fi
echo ""

# ─── wf-recorder ─────────────────────────────────────────────────────────────
echo "── wf-recorder ──────────────────────────────────────────────────"
command -v wf-recorder &>/dev/null && ok "wf-recorder installed" \
  || fail "wf-recorder MISSING — run: sudo pacman -S wf-recorder"
test -f ~/scripts/record-toggle.sh && ok "record-toggle.sh" \
  || skip "record-toggle.sh" "chezmoi apply needed"
test -f ~/scripts/ocr-screen.sh && ok "ocr-screen.sh" \
  || skip "ocr-screen.sh" "chezmoi apply needed"
command -v tesseract &>/dev/null && ok "tesseract (OCR) installed" \
  || skip "tesseract" "optional (sudo pacman -S tesseract tesseract-data-eng)"
echo ""

# ─── Bluetooth ───────────────────────────────────────────────────────────────
echo "── Bluetooth ────────────────────────────────────────────────────"
command -v bluetoothctl &>/dev/null && ok "bluez installed" \
  || skip "bluez" "optional (sudo pacman -S bluez)"
command -v bluetui &>/dev/null && ok "bluetui installed" \
  || skip "bluetui" "optional (paru -S bluetui)"
systemctl is-active --quiet bluetooth.service 2>/dev/null \
  && ok "bluetooth.service running" \
  || skip "bluetooth.service" "enable: systemctl enable --now bluetooth"
echo ""

# ─── Media stack ─────────────────────────────────────────────────────────────
echo "── Media stack ──────────────────────────────────────────────────"
command -v mpv      &>/dev/null && ok "mpv installed"      || fail "mpv MISSING (sudo pacman -S mpv)"
command -v swayimg  &>/dev/null && ok "swayimg installed"  || fail "swayimg MISSING (sudo pacman -S swayimg)"
command -v zathura  &>/dev/null && ok "zathura installed"  || fail "zathura MISSING (sudo pacman -S zathura)"
command -v cava     &>/dev/null && ok "cava installed"     || skip "cava"     "optional (sudo pacman -S cava)"
command -v ncspot   &>/dev/null && ok "ncspot installed"   || skip "ncspot"   "optional (paru -S ncspot)"
command -v lazydocker &>/dev/null && ok "lazydocker installed" || skip "lazydocker" "optional (paru -S lazydocker-bin)"
test -f ~/.config/mpv/mpv.conf      && ok "mpv.conf"      || skip "mpv.conf"      "chezmoi apply needed"
test -f ~/.config/swayimg/config    && ok "swayimg config" || skip "swayimg config" "chezmoi apply needed"
test -f ~/.config/zathura/zathurarc && ok "zathurarc"      || skip "zathurarc"      "chezmoi apply needed"
echo ""

# ─── Neovim plugins ──────────────────────────────────────────────────────────
echo "── Neovim plugins ───────────────────────────────────────────────"
if command -v nvim &>/dev/null; then
  ok "nvim installed: $(nvim --version 2>/dev/null | head -1)"
  test -f ~/.config/nvim/lua/plugins/blink.lua   && ok "blink.lua"   || fail "blink.lua MISSING (chezmoi apply needed)"
  test -f ~/.config/nvim/lua/plugins/snacks.lua  && ok "snacks.lua"  || fail "snacks.lua MISSING (chezmoi apply needed)"
  test -f ~/.config/nvim/lua/plugins/avante.lua  && ok "avante.lua"  || fail "avante.lua MISSING (chezmoi apply needed)"
  test -f ~/.config/nvim/lua/plugins/extras.lua  && ok "extras.lua"  || fail "extras.lua MISSING (chezmoi apply needed)"
else
  skip "nvim plugins" "nvim not found"
fi
echo ""

# ─── GTK/Qt theming ──────────────────────────────────────────────────────────
echo "── GTK/Qt theming ───────────────────────────────────────────────"
test -f ~/.config/gtk-3.0/settings.ini && ok "gtk-3.0 settings.ini" \
  || skip "gtk-3.0 settings" "run nwg-look to generate"
command -v qt6ct &>/dev/null && ok "qt6ct installed" \
  || fail "qt6ct MISSING (sudo pacman -S qt6ct)"
test -f ~/.config/fontconfig/fonts.conf && ok "fontconfig/fonts.conf" \
  || fail "fontconfig/fonts.conf MISSING"
grep -q 'Inter\|sans-serif' ~/.config/fontconfig/fonts.conf 2>/dev/null \
  && ok "Inter mapped as sans-serif" \
  || fail "sans-serif not remapped to Inter in fontconfig"
echo ""

# ─── Backup ──────────────────────────────────────────────────────────────────
echo "── Backup ───────────────────────────────────────────────────────"
command -v restic &>/dev/null && ok "restic installed" \
  || skip "restic" "optional (sudo pacman -S restic)"
test -f ~/scripts/backup.sh && ok "backup.sh" \
  || skip "backup.sh" "chezmoi apply needed"
systemctl --user is-enabled restic-backup.timer 2>/dev/null \
  && ok "restic-backup.timer enabled" \
  || skip "restic-backup.timer" "enable: systemctl --user enable --now restic-backup.timer"
echo ""

# ─── TTY autologin ───────────────────────────────────────────────────────────
echo "── TTY autologin ────────────────────────────────────────────────"
test -f /etc/systemd/system/getty@tty1.service.d/autologin.conf \
  && ok "getty autologin configured" \
  || skip "getty autologin" "run: ~/.config/SL1C3D-L4BS/system-config/install-getty-autologin.sh"
! systemctl is-enabled sddm.service 2>/dev/null \
  && ok "sddm disabled/absent (correct)" \
  || fail "sddm.service is enabled — disable: systemctl disable sddm"
echo ""

# ─── atuin ───────────────────────────────────────────────────────────────────
echo "── atuin ────────────────────────────────────────────────────────"
if command -v atuin &>/dev/null; then
  ok "atuin installed: $(atuin --version 2>/dev/null | head -1)"
  test -f ~/.config/atuin/config.toml && ok "config.toml" || fail "config.toml MISSING (chezmoi apply needed)"
  test -f ~/.config/atuin/themes/sl1c3d.toml && ok "sl1c3d theme" || skip "sl1c3d theme" "chezmoi apply needed"
else
  skip "atuin" "optional"
fi
echo ""

# ─── OpenClaw (optional) ─────────────────────────────────────────────────────
echo "── OpenClaw ─────────────────────────────────────────────────────"
command -v openclaw &>/dev/null && ok "openclaw installed" || skip "openclaw" "optional"
test -f ~/.openclaw/openclaw.json && ok "openclaw.json" || skip "openclaw.json" "optional"
if command -v curl &>/dev/null; then
  code="$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 1 http://127.0.0.1:18789/ 2>/dev/null)" || code=""
  [ "$code" = "200" ] && ok "gateway :18789 reachable" || skip "gateway :18789" "not running"
fi
echo ""

# ─── Chezmoi source integrity ─────────────────────────────────────────────────
echo "── Chezmoi source ───────────────────────────────────────────────"
if command -v chezmoi &>/dev/null; then
  ok "chezmoi installed: $(chezmoi --version 2>/dev/null | head -1)"
  test -f ~/.local/share/chezmoi/.chezmoidata.toml && ok ".chezmoidata.toml" \
    || fail ".chezmoidata.toml MISSING"
  test -f ~/.local/share/chezmoi/.chezmoi.toml.tmpl && ok ".chezmoi.toml.tmpl" \
    || skip ".chezmoi.toml.tmpl" "optional (age encryption template)"
  chezmoi doctor 2>/dev/null | grep -q 'ok\|warning' \
    && ok "chezmoi doctor: no fatal errors" \
    || skip "chezmoi doctor" "run manually: chezmoi doctor"
else
  fail "chezmoi not installed"
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
