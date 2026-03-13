#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS 2026 Masterclass — Full install script
# Run ONCE after base install. Installs all packages for the masterclass stack.
# Login: getty autologin (TTY only — no display manager)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║         SL1C3D-L4BS 2026 Masterclass Install                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Phase 0: Critical fixes ──────────────────────────────────────────────────
echo "── Phase 0: Critical fixes ──────────────────────────────────────"
sudo pacman -S --noconfirm --needed \
  noto-fonts noto-fonts-emoji inter-font \
  adw-gtk-theme qt6ct qt5ct kvantum kvantum-qt5 \
  xdg-desktop-portal-gtk \
  gnome-keyring libsecret seahorse

echo ""
echo "── Phase 1: Foundation ──────────────────────────────────────────"
sudo pacman -S --noconfirm --needed age

echo ""
echo "── Phase 2: Dynamic theming ──────────────────────────────────────"
sudo pacman -S --noconfirm --needed swaync

echo ""
echo "── Phase 2 (AUR): matugen ────────────────────────────────────────"
paru -S --noconfirm --needed matugen-bin

echo ""
echo "── Phase 3: Tool replacements ────────────────────────────────────"
sudo pacman -S --noconfirm --needed \
  satty \
  kanshi \
  hyprsunset \
  wf-recorder \
  hyprpicker

echo ""
echo "── Phase 3 (AUR): hyprpolkitagent ──────────────────────────────────"
paru -S --noconfirm --needed \
  hyprpolkitagent

echo ""
echo "── Phase 7: Media stack ──────────────────────────────────────────"
sudo pacman -S --noconfirm --needed \
  mpv \
  swayimg \
  zathura \
  zathura-pdf-mupdf \
  cava \
  tesseract \
  tesseract-data-eng \
  restic

echo ""
echo "── Phase 7-8 (AUR): ncspot, lazydocker ─────────────────────────────"
paru -S --noconfirm --needed \
  ncspot \
  lazydocker-bin

echo ""
echo "── Phase 8-9: Security + Bluetooth ──────────────────────────────"
sudo pacman -S --noconfirm --needed \
  rbw \
  pinentry-bemenu \
  bluez \
  bluez-utils

echo ""
echo "── Phase 9 (AUR): bluetui ────────────────────────────────────────"
paru -S --noconfirm --needed bluetui

echo ""
echo "── Phase 10: Browser (AUR) ───────────────────────────────────────"
paru -S --noconfirm --needed zen-browser-bin

echo ""
echo "── GTK/Qt theming (AUR) ─────────────────────────────────────────"
paru -S --noconfirm --needed nwg-look

echo ""
echo "── Post-install: Enable services ────────────────────────────────"
sudo systemctl enable bluetooth.service || echo "Bluetooth: enable manually"
systemctl --user enable --now kanshi.service 2>/dev/null || echo "kanshi: enable after Hyprland session"
systemctl --user enable restic-backup.timer 2>/dev/null || true

echo ""
echo "── Post-install: Age keygen ──────────────────────────────────────"
if [[ ! -f "$HOME/.age/key.txt" ]]; then
  mkdir -p ~/.age
  age-keygen -o ~/.age/key.txt
  echo ""
  echo "  IMPORTANT: Back up your age key at ~/.age/key.txt OFFLINE!"
  echo "  Add the public key to chezmoi.toml [age] recipient field."
fi

echo ""
echo "── Post-install: PAM keyring ─────────────────────────────────────"
if ! grep -q 'pam_gnome_keyring' /etc/pam.d/login 2>/dev/null; then
  echo ""
  echo "  Add these lines to /etc/pam.d/login:"
  echo "    auth     optional pam_gnome_keyring.so"
  echo "    session  optional pam_gnome_keyring.so auto_start"
fi

echo ""
echo "── Post-install: chezmoi apply ──────────────────────────────────"
chezmoi apply

echo ""
echo "── Post-install: fc-cache ───────────────────────────────────────"
fc-cache -fv

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Install complete! Run ~/scripts/validate-configs.sh         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Set GTK theme: nwg-look → adw-gtk3-dark, Papirus-Dark, Inter 11"
echo "  2. Configure qt6ct: Style=Kvantum, Font=JetBrains Mono Nerd Font"
echo "  3. rbw setup: rbw config set email <your@email> && rbw login"
echo "  4. GPG signing: follow instructions in ~/.config/git/config"
echo "  5. Backup: secret-tool store --label='restic' service restic repo local"
echo "  6. Test matugen: matugen image ~/assets/wallpapers/sl1c3d-l4bs-09.png -m dark"
