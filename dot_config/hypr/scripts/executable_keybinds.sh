#!/usr/bin/env bash
# SL1C3D-L4BS — show keybind cheatsheet in Fuzzel (read-only). Bind to Super+/
# Usage: keybinds.sh (no args)

set -e
LIST="Terminal	Super+Return
Close window	Super+Q
Exit / shutdown	Super+M
File manager	Super+F
btop	Super+B
Lazygit	Super+G
Toggle float	Super+V
Launcher	Super+Space
Toggle split	Super+J
Workspace 1–10	Super+1..0
Move window to workspace	Super+Shift+1..0
Scratchpad (toggle)	Super+S
Scratchpad (move)	Super+Shift+S
Focus left/right/up/down	Super+Arrow
Lock screen	Super+L
Window overview	Super+A
Keybinds (this)	Super+/
Dismiss notification	Super+N
Dismiss all notifications	Super+Shift+N
Do not disturb	Super+D / Super+Shift+D
Volume / brightness	XF86* keys
Media	XF86Audio*"

if command -v fuzzel &>/dev/null; then
  echo "$LIST" | fuzzel --dmenu --no-fuzzy-match --width 60 --lines 22 2>/dev/null || true
else
  echo "$LIST"
fi
