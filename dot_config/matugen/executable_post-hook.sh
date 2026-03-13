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

echo "[matugen post-hook] Daemons signaled. Theme applied."
