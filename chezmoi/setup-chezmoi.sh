#!/usr/bin/env bash
# setup-chezmoi.sh — initialize chezmoi to manage dotfiles from this repo
# Run once after bootstrap.sh installs chezmoi.

set -euo pipefail

DOTS="$HOME/dev/.dotfiles"

if ! command -v chezmoi &>/dev/null; then
    echo '{"error":"chezmoi not installed","hint":"yay -S chezmoi or nix run nixpkgs#chezmoi"}' >&2
    exit 1
fi

# Init chezmoi pointing to this repo
chezmoi init --source "$DOTS"

# Add all configs chezmoi should manage
declare -a PATHS=(
    "$HOME/.zshenv"
    "$HOME/.config/i3"
    "$HOME/.config/alacritty"
    "$HOME/.config/polybar"
    "$HOME/.config/rofi"
    "$HOME/.config/picom"
    "$HOME/.config/nvim"
    "$HOME/.config/atuin"
    "$HOME/.config/btop"
    "$HOME/.config/direnv"
    "$HOME/.config/shell"
    "$HOME/.config/theme"
    "$HOME/.local/bin"
)

for p in "${PATHS[@]}"; do
    [[ -e "$p" ]] && chezmoi add "$p" 2>/dev/null || true
done

echo "{\"status\":\"chezmoi initialized\",\"source\":\"$DOTS\"}"
echo "Run 'chezmoi apply' to sync, 'chezmoi diff' to preview changes."
