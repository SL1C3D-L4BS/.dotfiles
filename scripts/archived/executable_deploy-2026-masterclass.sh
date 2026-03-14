#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS 2026 Masterclass Deploy Script
#
# DOES IN ORDER:
#   1. Install all 2026 masterclass packages (pacman + paru)
#   2. Remove all legacy tools (mako, fuzzel, polkit-gnome, hyprpaper, etc.)
#   3. Enable required systemd services
#   4. One-time setup (age keygen, PAM keyring)
#   5. chezmoi apply (push all configs to live system)
#   6. fc-cache + reload daemons
#   7. Full validation via validate-configs.sh
#
# Login: getty autologin on TTY1 — no display manager.
# Run from a terminal (not Zellij). Requires paru in PATH.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

step()  { echo -e "\n${CYAN}${BOLD}══ $1 ${RESET}"; }
ok()    { echo -e "  ${GREEN}✔${RESET}  $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
die()   { echo -e "  ${RED}✘  FATAL: $1${RESET}"; exit 1; }

# ── Guards ────────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] && die "Do NOT run as root. Script uses sudo internally."
command -v paru &>/dev/null || die "paru not found. Install paru first: https://github.com/Morganamilo/paru"
command -v chezmoi &>/dev/null || die "chezmoi not found."

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║      SL1C3D-L4BS 2026 Masterclass — Full Deploy             ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Install all 2026 masterclass packages
# ─────────────────────────────────────────────────────────────────────────────
step "1/7  Installing pacman packages"

PACMAN_PKGS=(
  # Phase 0: Critical fixes
  noto-fonts noto-fonts-emoji inter-font
  adw-gtk-theme qt6ct qt5ct kvantum kvantum-qt5
  xdg-desktop-portal-gtk
  gnome-keyring libsecret seahorse

  # Phase 1: Foundation
  age

  # Phase 2: Dynamic theming
  swaync

  # Phase 3: Tool replacements
  satty
  kanshi
  hyprsunset
  wf-recorder
  hyprpicker

  # Phase 7: Media stack
  mpv
  swayimg
  zathura zathura-pdf-mupdf
  cava
  tesseract tesseract-data-eng
  restic

  # Phase 8-9: Security + Bluetooth
  rbw pinentry-bemenu
  bluez bluez-utils

  # Dev tools used in scripts
  jq wl-clipboard grim slurp
)

sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}" \
  && ok "pacman packages installed" \
  || die "pacman install failed"

step "1b/7  Installing AUR packages"

AUR_PKGS=(
  matugen-bin
  hyprpolkitagent
  bluetui
  lazydocker-bin
  ncspot
  zen-browser-bin
  nwg-look
)

paru -S --noconfirm --needed "${AUR_PKGS[@]}" \
  && ok "AUR packages installed" \
  || warn "Some AUR packages failed — check paru output above"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Remove legacy tools
# ─────────────────────────────────────────────────────────────────────────────
step "2/7  Removing legacy tools"

LEGACY_PKGS=(
  mako            # replaced by swaync
  polkit-gnome    # replaced by hyprpolkitagent
  hyprpaper       # removed (using swww)
  sddm            # removed — TTY autologin only
)

for pkg in "${LEGACY_PKGS[@]}"; do
  if pacman -Qi "$pkg" &>/dev/null; then
    sudo pacman -Rns --noconfirm "$pkg" \
      && ok "Removed: $pkg" \
      || warn "Could not remove $pkg (may have dependents — check manually)"
  else
    ok "Already absent: $pkg"
  fi
done

# Remove legacy config dirs from live system (chezmoi source already cleaned)
LEGACY_DIRS=(
  ~/.config/mako
  ~/.config/fuzzel
)
for d in "${LEGACY_DIRS[@]}"; do
  if [[ -d "$d" ]]; then
    rm -rf "$d" && ok "Removed legacy dir: $d"
  fi
done

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Enable systemd services
# ─────────────────────────────────────────────────────────────────────────────
step "3/7  Enabling systemd services"

# System services
SYSTEM_SERVICES=(bluetooth.service)
for svc in "${SYSTEM_SERVICES[@]}"; do
  if systemctl is-enabled "$svc" &>/dev/null; then
    ok "$svc already enabled"
  else
    sudo systemctl enable "$svc" && ok "Enabled: $svc" || warn "Could not enable $svc"
  fi
done

# User services (need graphical session, enable only)
USER_SERVICES=(kanshi.service restic-backup.timer)
for svc in "${USER_SERVICES[@]}"; do
  systemctl --user enable "$svc" 2>/dev/null && ok "User service enabled: $svc" \
    || warn "$svc: enable after first Hyprland login (needs graphical session target)"
done

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: One-time setup tasks
# ─────────────────────────────────────────────────────────────────────────────
step "4/7  One-time setup"

# ── age keygen ────────────────────────────────────────────────────────────────
if [[ ! -f "$HOME/.age/key.txt" ]]; then
  mkdir -p ~/.age
  age-keygen -o ~/.age/key.txt 2>&1 | head -5
  chmod 600 ~/.age/key.txt
  AGE_PUBKEY=$(grep "^# public key:" ~/.age/key.txt | awk '{print $NF}')
  ok "age key generated: $AGE_PUBKEY"
  echo ""
  warn "ACTION REQUIRED: Add this public key to ~/.config/chezmoi/chezmoi.toml:"
  warn "  [age]"
  warn "    recipient = \"$AGE_PUBKEY\""
  warn "  Back up ~/.age/key.txt OFFLINE."
else
  AGE_PUBKEY=$(grep "^# public key:" ~/.age/key.txt 2>/dev/null | awk '{print $NF}' || echo "existing")
  ok "age key exists ($AGE_PUBKEY)"
fi

# ── PAM gnome-keyring ─────────────────────────────────────────────────────────
if ! grep -q 'pam_gnome_keyring' /etc/pam.d/login 2>/dev/null; then
  warn "PAM keyring not configured. Adding to /etc/pam.d/login..."
  sudo bash -c 'cat >> /etc/pam.d/login <<EOF
# gnome-keyring — SL1C3D-L4BS 2026
auth     optional pam_gnome_keyring.so
session  optional pam_gnome_keyring.so auto_start
EOF'
  ok "PAM gnome-keyring configured"
else
  ok "PAM gnome-keyring already configured"
fi

# ── XDG mime defaults ─────────────────────────────────────────────────────────
if command -v xdg-mime &>/dev/null; then
  xdg-mime default zathura.desktop application/pdf 2>/dev/null && ok "pdf → zathura" || true
  xdg-mime default mpv.desktop video/mp4 2>/dev/null && ok "mp4 → mpv" || true
  xdg-mime default swayimg.desktop image/png 2>/dev/null && ok "png → swayimg" || true
  xdg-mime default swayimg.desktop image/jpeg 2>/dev/null && ok "jpg → swayimg" || true
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5: chezmoi apply
# ─────────────────────────────────────────────────────────────────────────────
step "5/7  Applying chezmoi (syncing all dotfiles to live system)"

if chezmoi verify 2>/dev/null; then
  ok "chezmoi verify: clean"
else
  warn "chezmoi verify found diffs — applying anyway"
fi

chezmoi apply --force \
  && ok "chezmoi apply: complete" \
  || die "chezmoi apply failed — check output above"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6: Reload daemons and caches
# ─────────────────────────────────────────────────────────────────────────────
step "6/7  Reloading caches and live daemons"

fc-cache -fv &>/dev/null && ok "fc-cache refreshed"
systemctl --user daemon-reload && ok "systemd user daemon reloaded"

if [[ -f ~/.config/fzf/fzf-colors.sh ]]; then
  ok "fzf-colors.sh in place (sourced by .zshrc)"
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  ok "Live Wayland session detected — signaling daemons"

  if command -v hyprctl &>/dev/null; then
    hyprctl reload 2>/dev/null && ok "hyprctl reload: OK" || warn "hyprctl reload failed"
  fi

  if pgrep -x swaync &>/dev/null; then
    swaync-client --reload-css 2>/dev/null && ok "swaync CSS reloaded" || warn "swaync reload failed"
  fi

  CURRENT_WALLPAPER=$(grep -E '^wallpaper\s*=' ~/.config/waypaper/config.ini 2>/dev/null \
    | cut -d'=' -f2- | xargs 2>/dev/null || echo "")
  if [[ -f "$CURRENT_WALLPAPER" ]]; then
    matugen image "$CURRENT_WALLPAPER" -m dark \
      && ok "matugen theme generated from: $(basename "$CURRENT_WALLPAPER")" \
      || warn "matugen failed — run manually: matugen image <wallpaper> -m dark"
  else
    FALLBACK=$(find ~/assets/wallpapers -name "*.png" 2>/dev/null | head -1)
    if [[ -f "$FALLBACK" ]]; then
      matugen image "$FALLBACK" -m dark \
        && ok "matugen theme generated (fallback wallpaper)" \
        || warn "matugen failed"
    else
      warn "No wallpaper found for matugen — run: matugen image <path> -m dark"
    fi
  fi

  if pgrep -x quickshell &>/dev/null; then
    pkill -SIGUSR1 quickshell 2>/dev/null && ok "quickshell signaled" || true
  fi
else
  warn "No Wayland session — daemon signals skipped (run after login)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 7: Full validation
# ─────────────────────────────────────────────────────────────────────────────
step "7/7  Running full validation"
echo ""

VALIDATE_SCRIPT="$HOME/scripts/validate-configs.sh"
if [[ -x "$VALIDATE_SCRIPT" ]]; then
  bash "$VALIDATE_SCRIPT" || VALIDATION_FAILED=1
else
  warn "validate-configs.sh not found or not executable"
  VALIDATION_FAILED=1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
if [[ -z "${VALIDATION_FAILED:-}" ]]; then
  echo -e "${BOLD}${GREEN}║  Deploy complete. SL1C3D-L4BS 2026 stack is live.           ║${RESET}"
else
  echo -e "${BOLD}${YELLOW}║  Deploy done — validation has warnings. See above.          ║${RESET}"
fi
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo "Post-deploy checklist:"
echo "  1. GTK theme:    nwg-look  → adw-gtk3-dark, Papirus-Dark, Inter 11"
echo "  2. Qt theme:    qt6ct     → Style=Kvantum, Font=JetBrains Mono Nerd Font"
echo "  3. Age key:     Add public key to ~/.config/chezmoi/chezmoi.toml [age] recipient"
echo "  4. rbw setup:   rbw config set email <your@email> && rbw login"
echo "  5. Restic pw:   secret-tool store --label='restic' service restic repo local"
echo "  6. GPG signing: See ~/.config/git/config for gpg key instructions"
echo "  7. Reboot:      Log out and back in to activate keyring PAM + bluetooth"
echo ""
echo "  Run again after reboot to re-validate (daemon signals will succeed in session)."
echo ""

step "  Syncing chezmoi source to git"
cd "$(chezmoi source-path)"
git add -A
git status --short
git commit -m "$(cat <<'EOF'
chore(dotfiles): 2026 masterclass stack deploy

- matugen dynamic theming pipeline (12 templates)
- swaync replaces mako, fuzzel launcher
- hyprpolkitagent replaces polkit-gnome
- satty screenshot annotation, kanshi monitor profiles
- hyprsunset, wf-recorder, hyprpicker, OCR script
- blink.cmp, snacks.nvim, avante.nvim Neovim stack
- Quickshell AIPanel + BluetoothWidget + swaync count
- atuin sl1c3d theme, Zellij ide layout, rbw picker
- age encryption, gnome-keyring, GPG signing setup
- restic backup systemd timer
- TTY autologin only — no display manager
- Full validate-configs.sh + deploy script
EOF
)" 2>/dev/null && ok "chezmoi git committed" || warn "Nothing new to commit (already clean)"
