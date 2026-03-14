#!/usr/bin/env bash
# Start Zellij with SL1C3D-L4BS: new session per terminal. Name must be < ~40 chars (socket path limit).

# Clear dead sessions in background so first terminal opens immediately (no block on boot)
( zellij delete-all-sessions -y 2>/dev/null & )

# Unique short name (Zellij session names are limited by Unix socket path length)
SESSION_NAME="sl1c3d-$$"
exec zellij -s "$SESSION_NAME" "$@"
