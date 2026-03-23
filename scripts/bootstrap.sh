#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
# bootstrap.sh — fresh Arch install → elite workstation
# Run ONCE after base Arch install as the_architect user
# ══════════════════════════════════════════════════════════════
set -euo pipefail

log()  { echo -e "\033[1;34m[BOOT]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }

# ── Step 1: yay AUR helper ────────────────────────────────────
if ! command -v yay &>/dev/null; then
    log "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm && cd -
fi
ok "yay ready"

# ── Step 2: Install all packages ──────────────────────────────
log "Installing packages via yay..."
yay -S --needed --noconfirm \
    zsh \
    alacritty \
    neovim \
    polybar \
    rofi \
    picom \
    fzf \
    zoxide \
    atuin \
    starship \
    lazygit \
    btop \
    eza \
    bat \
    ripgrep \
    fd \
    git-delta \
    direnv \
    github-cli \
    matugen \
    chezmoi \
    feh \
    i3lock \
    xss-lock \
    xclip \
    maim \
    brightnessctl \
    numlockx \
    duf \
    dust \
    procs \
    jq \
    python-duckdb \
    python-psycopg2 \
    age \
    ttf-jetbrains-mono-nerd \
    noto-fonts-emoji \
    papirus-icon-theme \
    greenclip \
    wmname \
    wmctrl
ok "Packages installed"

# ── Step 3: Install Nix ───────────────────────────────────────
if ! command -v nix &>/dev/null; then
    log "Installing Nix (single-user)..."
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
ok "Nix ready"

# Enable flakes
mkdir -p "$HOME/.config/nix"
cat >> "$HOME/.config/nix/nix.conf" <<'EOF' 2>/dev/null || true
experimental-features = nix-command flakes
keep-outputs = true
keep-derivations = true
EOF

# ── Step 4: Install home-manager ──────────────────────────────
if ! command -v home-manager &>/dev/null; then
    log "Installing home-manager..."
    nix run nixpkgs#home-manager -- init --switch
fi
ok "home-manager ready"

# ── Step 5: Link dotfiles ─────────────────────────────────────
DOTS="$HOME/dev/.dotfiles"
log "Linking dotfiles..."

# i3
mkdir -p ~/.config/i3/config.d
cp -r "$DOTS/home/.config/i3/"* ~/.config/i3/

# polybar
mkdir -p ~/.config/polybar
cp -r "$DOTS/home/.config/polybar/"* ~/.config/polybar/
chmod +x ~/.config/polybar/launch.sh

# rofi
mkdir -p ~/.config/rofi/themes
cp -r "$DOTS/home/.config/rofi/"* ~/.config/rofi/

# alacritty
mkdir -p ~/.config/alacritty
cp "$DOTS/home/.config/alacritty/alacritty.toml" ~/.config/alacritty/
cp "$DOTS/home/.config/alacritty/theme.toml" ~/.config/alacritty/

# shell
mkdir -p ~/.config/shell
cp "$DOTS/home/.config/shell/zshrc"     ~/.config/shell/zshrc
cp "$DOTS/home/.config/shell/starship.toml" ~/.config/shell/starship.toml

# nvim
cp -r "$DOTS/home/.config/nvim" ~/.config/

# theme
cp -r "$DOTS/home/.config/theme" ~/.config/

# CLIs
mkdir -p ~/.local/bin
cp "$DOTS/home/.local/bin/"* ~/.local/bin/
chmod +x ~/.local/bin/*

ok "Dotfiles linked"

# ── Step 6: Set zsh as default shell ──────────────────────────
if [[ "$SHELL" != "$(which zsh)" ]]; then
    log "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
fi

# Link zshrc
ln -sf ~/.config/shell/zshrc ~/.zshrc
ln -sf ~/.config/shell/starship.toml ~/.config/starship.toml
ok "Shell configured"

# ── Step 7: Keys init ─────────────────────────────────────────
if [[ ! -f ~/.config/keys/identity.age ]]; then
    log "Initializing age keystore..."
    ~/.local/bin/keys-rotate --init
fi
ok "Keys ready"

# ── Step 8: Create wallpaper dir ──────────────────────────────
mkdir -p ~/Pictures/wallpapers

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo "  Elite workstation bootstrap complete."
echo "  Restart i3: \$mod+Shift+r"
echo "  Switch theme: \$mod+Shift+t"
echo "  Set wallpaper: theme-switch"
echo "════════════════════════════════════════════"
