# SL1C3D-L4BS — Assets (chezmoi)

After `chezmoi apply`, these are available at **~/assets/**.

- **icons/** — Logo.svg (brand icon)
- **wallpapers/** — SL1C3D-L4BS wallpapers (sl1c3d-l4bs-01.png … 15). See wallpapers/README.md.

**Usage:** Point Hyprland (hyprpaper), Waypaper, Wallust, or any wallpaper chooser at `~/assets/wallpapers`. Use `~/assets/icons/Logo.svg` for app icons or UI.

**Optional symlink** (e.g. for scripts that expect a config path):
```bash
mkdir -p ~/.config/sl1c3d && ln -sfn ~/assets/wallpapers ~/.config/sl1c3d/wallpapers
```
