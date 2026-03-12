#!/usr/bin/env bash
# SL1C3D-L4BS — Elite 2026 CLI stack (atuin, fastfetch, btop, delta, zoxide, eza, bat, fd, ripgrep, lazygit)
# Run: ./install-elite-stack.sh

set -e

echo "[SL1C3D-L4BS] Installing elite stack..."
sudo pacman -S --needed --noconfirm \
  atuin fastfetch btop git-delta zoxide eza bat fd ripgrep lazygit

echo "[SL1C3D-L4BS] Elite stack installed. Run 'atuin import auto' to import existing history (optional)."
