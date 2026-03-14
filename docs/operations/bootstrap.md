## Bootstrap — First-Time Setup

This bootstrap guide is aligned with:

- Phase 0 inventory and install paths: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (package sources, session targets, TTY-only): `docs/inventory/phase0-decisions.md`
- Phase 0 do-not-break list: `docs/inventory/phase0-do-not-break.md`

It **does not** assume `chezmoi apply` on login; all configuration application is explicit.

---

### 1. Five-Part Bootstrap Order

Stack: **Arch/linux-zen (host)** → **TTY + systemd user (session)** → **Nix (packages/devShells)** → **Chezmoi (config/state)** → **sl1c3d (operations)**.

For a new machine:

1. **Host (Arch / linux-zen)**  
   - Install base Arch; use **linux-zen** kernel if desired. Create user account.  
   - Install **host and session-core only** via pacman/AUR (Hyprland, PipeWire, XDG portals, quickshell, swaync, ghostty, fuzzel, etc.). Use scripts under `dot_config/SL1C3D-L4BS/system-config/` (e.g. install scripts that pull session-core and host packages; do **not** install toolchain/languages from pacman — those come from Nix).  
   - Configure getty autologin on TTY1 if needed.

2. **Nix (packages + devShells)**  
   - Install Nix (DeterminateSystems installer or official).  
   - Clone the dotfiles repo (or ensure `nix/` is available). Then:
     ```bash
     cd ~/.local/share/chezmoi && nix profile install .#default
     ```
   - This installs toolchain, languages, LSPs, formatters, linters. Shell config (chezmoi) will prepend Nix profile to PATH so Nix wins. Use `nix develop` for project shells.

3. **Chezmoi (config / state)**  
   - Install chezmoi (pacman/AUR or official script). Clone the dotfiles repo into `~/.local/share/chezmoi`.  
   - Apply config and state:
     ```bash
     chezmoi init --apply <REPO>
     # or: chezmoi apply
     ```
   - No `chezmoi apply` on login; apply is explicit only.

4. **Session (TTY + systemd user units)**  
   - Enable systemd user units (run in a user session so `systemctl --user` works):
     ```bash
     systemctl --user daemon-reload
     systemctl --user enable quickshell.service swaync.service clipboard-history.service \
       swww.service wallpaper-restore.service hypridle.service theme-propagation.service
     ```
   - Log in on TTY; Hyprland starts directly. Autostart runs env export then `systemctl --user start` for the daemon set.

5. **Operations (sl1c3d)**  
   - Validate: `sl1c3d validate` (or `~/scripts/validate-configs.sh`).  
   - Health: `sl1c3d doctor`.  
   - Going forward: use `sl1c3d` for repair, benchmark, theme, edition, bootstrap, session — not ad-hoc scripts.

This sequence deliberately avoids any automatic `chezmoi apply` at login.

---

### 2. Session Model (TTY-Only)

Phase 6 has moved durable daemons to systemd user units. Session is **TTY-only** (no UWSM, no display manager). User logs in on TTY; Hyprland starts directly. `autostart.conf` runs `dbus-update-activation-environment` and portal start, then `systemctl --user start` for the durable-daemon set. User units are enabled in step 5 above.

---

### 3. Rollback Considerations

- If a bootstrap attempt introduces instability:
  - Re-run `~/scripts/validate-configs.sh` to confirm config integrity.  
  - Use `chezmoi diff` and VCS history to revert recent changes to the chezmoi source.  
  - Reapply dotfiles only after confirming the rollback steps.
- **Bootstrap package rollback:** Each bootstrap run writes package lists to `~/.config/SL1C3D-L4BS/state/bootstrap/<timestamp>-<edition>/` (`pacman-qqe-before.txt`, and `aur-qe-before.txt` if paru/yay was used). To restore the pre-bootstrap package set, reinstall from those lists or revert manually (e.g. `pacman -S - < pacman-qqe-before.txt` for native packages; AUR per your helper).

Package ownership: **Arch** = host + session-core; **Nix** = user packages, toolchain, languages, LSPs, formatters, devShells. Rollback per `docs/architecture/package-inventory.md` and migration ledger.

---

### 4. Fullstack 1–4 execution (short path)

Minimal path to apply config, ensure edition, validate, and confirm the Control Plane hub and glass tokens:

1. **Apply config:** `chezmoi apply` or one-command install via `get.sh` (get.sh runs `sl1c3d-edition set base` if `~/.config/hypr/edition.conf` is missing).
2. **Ensure edition (if not using get.sh):** If `~/.config/hypr/edition.conf` is missing, run `~/.config/SL1C3D-L4BS/bin/sl1c3d-edition set base`. Optionally run `~/.config/SL1C3D-L4BS/system-config/bootstrap.sh --edition base` to install packages and enable services from the edition manifest.
3. **Validate:** `~/scripts/validate-configs.sh` and `~/scripts/run-golden-suite.sh` (or `sl1c3d validate`).
4. **Session check:** Start Hyprland; open the bar logo (Control Plane Hub) and AGS quicksettings (e.g. Super+I) to confirm glass styling and design tokens.

