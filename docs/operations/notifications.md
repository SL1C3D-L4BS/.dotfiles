# Notifications (swaync) — SL1C3D-L4BS

Swaync is the notification daemon. All notifications auto-dismiss (normal 6s, low 4s, critical 30s). This doc lists what is wired and how to add more.

## Auto-dismiss (config.json)

- **timeout**: 6 (normal priority)
- **timeout-low**: 4 (low priority)
- **timeout-critical**: 30 (critical still dismiss after 30s)

## Wired notification sources

| Source | How | Config / script |
|--------|-----|------------------|
| Volume up/down/mute | Fn keys → volume-notify.sh | dot_config/hypr/scripts/volume-notify.sh, binds.conf |
| Brightness up/down | Fn keys → brightness-notify.sh | dot_config/hypr/scripts/brightness-notify.sh, binds.conf |
| Screenshot | Print / Super+Print → screenshot.sh | dot_config/hypr/scripts/screenshot.sh |
| Screen recording | wf-recorder → record-toggle.sh | dot_config/hypr/scripts/record-toggle.sh |
| Backup complete | restic → backup.sh | scripts/backup.sh |
| Dev timer | dev-timer.sh alarm | dot_config/hypr/scripts/dev-timer.sh |
| Spotifyd start/stop | spotifyd-toggle.sh | dot_config/hypr/scripts/spotifyd-toggle.sh |
| OCR result | ocr-screen.sh | dot_config/hypr/scripts/ocr-screen.sh |
| rbw (password) | rbw-picker.sh | scripts/rbw-picker.sh |

## Optional: more coverage

- **System updates**: Script `scripts/check-updates-notify.sh` notifies when `checkupdates` (pacman-contrib) reports packages. To enable the daily check:
  1. `chezmoi apply` (so `~/.config/systemd/user/check-updates-notify.{timer,service}` exist)
  2. `systemctl --user daemon-reload`
  3. `systemctl --user enable --now check-updates-notify.timer`
- **Battery (laptop)**: Use a udev rule or a user timer that runs `upower` or reads `/sys/class/power_supply/` and sends `notify-send -u critical` when below a threshold or when charged.
- **Calendar/reminders**: Use a client that emits desktop notifications (e.g. GNOME Calendar, khal with a notify hook).
- **Build/IDE**: Most IDEs and `ninja`/`make` wrappers can run a command on completion; add `notify-send -a "Build" "Done"` to your build script or IDE run configuration.

## Keybinds

- Super+N: close latest notification
- Super+Shift+N: close all
- Super+D: toggle Do Not Disturb
- Super+Shift+I: toggle control center panel
