#!/usr/bin/env bash
# spotifyd-toggle.sh — start/stop spotifyd daemon with notification feedback
# Bound to Super+Shift+M in Hyprland

ICON="$HOME/assets/icons/phosphor/music-notes.svg"

is_running() {
    systemctl --user is-active --quiet spotifyd 2>/dev/null
}

case "${1:-toggle}" in
    start)
        systemctl --user start spotifyd
        notify-send -u low -i "$ICON" "SL1C3D Music" "spotifyd started — control via Hub Media tab"
        ;;
    stop)
        playerctl --player=spotifyd stop 2>/dev/null || true
        systemctl --user stop spotifyd
        notify-send -u low -i "$ICON" "SL1C3D Music" "spotifyd stopped"
        ;;
    toggle)
        if is_running; then
            playerctl --player=spotifyd stop 2>/dev/null || true
            systemctl --user stop spotifyd
            notify-send -u low -i "$ICON" "SL1C3D Music" "spotifyd stopped"
        else
            systemctl --user start spotifyd
            notify-send -u low -i "$ICON" "SL1C3D Music" "spotifyd started — open Spotify app to play"
        fi
        ;;
    status)
        if is_running; then
            echo "running"
        else
            echo "stopped"
        fi
        ;;
esac
