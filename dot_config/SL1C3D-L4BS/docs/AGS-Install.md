# AGS (Aylur's GTK Shell) — Install notes (SL1C3D-L4BS)

## Important: `ags` name conflict
On Arch, **`ags` may already be taken** by **Adventure Game Studio** (which prints `Adventure Game Studio` in `ags --version`).

SL1C3D-L4BS requires **Aylur's GTK Shell** (package commonly named `aylurs-gtk-shell`) which also provides an `ags` binary.

### Check
Run:

```bash
~/.config/SL1C3D-L4BS/bin/sl1c3d-ags doctor
```

If it says "Adventure Game Studio", uninstall/rename the conflicting package, then install `aylurs-gtk-shell`.

## Running and toggle
- **Autostart:** Hyprland starts AGS from `~/.config/ags` after the bar (see `~/.config/hypr/autostart.conf`). Super+I toggles the quicksettings panel.
- **"no window registered with name 'quicksettings'":** Another AGS instance is running (e.g. from an old run or a different config). Quit it and start this config:
  ```bash
  ags quit
  ags run -d ~/.config/ags
  ```
  Then use Super+I (or `ags toggle quicksettings`) to toggle. After a reboot, autostart runs this config so you normally don't need to do this.
