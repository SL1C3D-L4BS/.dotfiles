#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Matugen post-hook — SL1C3D-L4BS
# Runs after matugen writes all template outputs.
# Signals running daemons to reload their color config.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ─── btop: reload theme on SIGUSR1 ───────────────────────────────────────────
pkill -SIGUSR1 btop 2>/dev/null || true

# ─── swaync: reload CSS (IPC command) ────────────────────────────────────────
if command -v swaync-client &>/dev/null; then
    swaync-client --reload-css 2>/dev/null || true
fi

# ─── Quickshell: reload by sending SIGUSR1 (live theme file watcher) ─────────
# Quickshell watches MatugenTheme.qml; file change triggers auto-reload.
# If not auto-reloaded, uncomment:
# pkill -SIGUSR1 quickshell 2>/dev/null || true

# ─── Zellij: theme is loaded at startup; new sessions get matugen theme ──────
# No live-reload possible; existing sessions keep current theme until restart.

# ─── SDDM background: copy wallpaper to SDDM assets (requires sudo) ─────────
# CURRENT_WALLPAPER=$(cat ~/.config/waypaper/config.ini 2>/dev/null | grep '^wallpaper' | cut -d= -f2 | xargs)
# if [[ -f "$CURRENT_WALLPAPER" ]]; then
#     sudo cp "$CURRENT_WALLPAPER" /usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds/background.png 2>/dev/null || true
# fi

# ─── Walker: themes are CSS-file based; restart if currently open ─────────────
pkill -HUP walker 2>/dev/null || true

echo "[matugen post-hook] Daemons signaled. Theme applied."
