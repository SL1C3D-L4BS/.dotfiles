# ── Login shell — auto-start X on TTY1 ────────────────────────
# Runs once on TTY login (not in X sessions or SSH)
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
    exec startx -- vt1
fi
