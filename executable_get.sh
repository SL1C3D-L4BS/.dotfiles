#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS one-command install: install chezmoi (if needed), init+apply repo.
# Usage: bash get.sh [REPO_URL]
#   REPO_URL = full git URL (e.g. https://github.com/you/SL1C3D-L4BS-dotfiles)
#   If omitted, uses SL1C3D_L4BS_REPO env var, else exits with usage.
# One-liner: bash <(curl -sL https://raw.githubusercontent.com/OWNER/REPO/main/get.sh) https://github.com/OWNER/REPO
# ─────────────────────────────────────────────────────────────────────────────

set -e
REPO="${1:-${SL1C3D_L4BS_REPO}}"
if [ -z "$REPO" ]; then
  echo "Usage: bash get.sh REPO_URL"
  echo "   or: SL1C3D_L4BS_REPO=REPO_URL bash get.sh"
  echo "Example: bash get.sh https://github.com/you/SL1C3D-L4BS-dotfiles"
  exit 1
fi

echo "[get.sh] Checking chezmoi..."
if ! command -v chezmoi &>/dev/null; then
  if [ -f /etc/arch-release ]; then
    if command -v paru &>/dev/null; then
      echo "[get.sh] Installing chezmoi via paru..."
      paru -S --noconfirm chezmoi
    elif command -v yay &>/dev/null; then
      echo "[get.sh] Installing chezmoi via yay..."
      yay -S --noconfirm chezmoi
    else
      echo "[get.sh] Install chezmoi: paru -S chezmoi (or yay), then re-run this script."
      exit 1
    fi
  else
    echo "[get.sh] Installing chezmoi via get.chezmoi.io..."
    BINDIR="${HOME}/.local/bin"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BINDIR"
    export PATH="$BINDIR:$PATH"
  fi
fi

echo "[get.sh] Applying dotfiles from $REPO..."
chezmoi init --apply "$REPO"

# Ensure Hyprland has a valid edition.conf (Fullstack 1-4 first-run guarantee)
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
EDITION_CONF="$CFG_DIR/hypr/edition.conf"
EDITION_BIN="$CFG_DIR/SL1C3D-L4BS/bin/sl1c3d-edition"
if [ ! -f "$EDITION_CONF" ] && [ -x "$EDITION_BIN" ]; then
  echo "[get.sh] First run: setting edition to base (creates $EDITION_CONF)..."
  "$EDITION_BIN" set base
fi

echo ""
echo "=== After install ==="
echo "1. Log in to Hyprland (select Hyprland session at login)."
echo "2. Run: ~/scripts/validate-configs.sh"
echo "3. Open the hub (click bar logo) for dev paths, wallpapers, system."
echo "4. Press Super+/ for keybinds."
echo ""
