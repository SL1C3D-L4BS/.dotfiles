#!/bin/sh
# ── ~/.xinitrc — TTY → startx → i3 ───────────────────────────

# Source system xinitrc scripts (keyboard, dbus, etc.)
if [ -d /etc/X11/xinit/xinitrc.d ]; then
    for f in /etc/X11/xinit/xinitrc.d/*; do
        [ -x "$f" ] && . "$f"
    done
    unset f
fi

# XDG base dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# Nix environment
[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && \
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Monitor layout (before i3 starts)
~/.config/xrandr-setup.sh

# Xresources (colors)
[ -f "$HOME/.Xresources" ] && xrdb -merge "$HOME/.Xresources"

# Launch i3
exec i3
