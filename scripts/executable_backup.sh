#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS backup — restic to local/B2
# Runs nightly via systemd timer: restic-backup.timer
# Password stored in gnome-keyring via secret-tool
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

export RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-/mnt/backup/sl1c3d-l4bs}"
RESTIC_PASSWORD="$(secret-tool lookup service restic repo local 2>/dev/null)"
export RESTIC_PASSWORD

if [[ -z "$RESTIC_PASSWORD" ]]; then
    echo "ERROR: Restic password not found in keyring."
    echo "Store it: secret-tool store --label='restic' service restic repo local"
    exit 1
fi

BACKUP_SOURCES=(
    "$HOME/Documents"
    "$HOME/Pictures"
    "$HOME/Videos"
    "$HOME/.local/share/atuin"
    "$HOME/.local/share/chezmoi"
    "$HOME/.config/SL1C3D-L4BS"
)

EXCLUDES=(
    --exclude-caches
    --exclude="$HOME/.cache"
    --exclude="$HOME/.local/share/Steam"
    --exclude="$HOME/.local/share/containers"
    --exclude="*.pyc"
    --exclude="__pycache__"
    --exclude="node_modules"
    --exclude=".git/objects"
    --exclude="*.tmp"
)

echo "[backup] Starting restic backup at $(date)"

restic backup \
    "${BACKUP_SOURCES[@]}" \
    "${EXCLUDES[@]}" \
    --verbose

# Keep: 7 daily, 4 weekly, 6 monthly
restic forget \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    --prune

echo "[backup] Backup complete at $(date)"

# Send notification (only if running in a user session, not pure systemd)
if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    notify-send --app-name="Backup" --icon=drive-harddisk \
        "Backup complete" "$(date '+%Y-%m-%d %H:%M')" --expire-time=5000
fi
