## Bootstrap — First-Time Setup

This bootstrap guide is aligned with:

- Phase 0 inventory and install paths: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (package sources, session targets, TTY-only): `docs/inventory/phase0-decisions.md`
- Phase 0 do-not-break list: `docs/inventory/phase0-do-not-break.md`

It **does not** assume `chezmoi apply` on login; all configuration application is explicit.

---

### 1. High-Level Sequence

For a new Arch machine:

1. **Install base system and user account** according to Arch documentation.  
2. **Install core tools via Arch packages**, following the scripts under `dot_config/SL1C3D-L4BS/system-config/` (Phase 7: `host/arch/` is the path of record; system-config remains the live source until artifacts are migrated with ledger entries — see `docs/architecture/migration-ledger.md`):
   - Examples: `install-elite-stack.sh`, `install-dev-stack.sh`, `install-openclaw-ollama.sh`, `install-sysctl.sh`, `install-pacman-conf.sh`.
3. **Install Nix (optional, Phase 8):**  
   - Install Nix (e.g. DeterminateSystems installer or official).  
   - From repo: `cd nix && nix profile install .#default` to install the CLI bundle, or `nix profile install .#neovim` etc. for individual packages. Configs remain in chezmoi; see `docs/architecture/package-ownership.md` for PATH precedence and duplicate-binary rules.
4. **Install chezmoi** and clone the dotfiles repo into `~/.local/share/chezmoi` as described in `README.md`.  
5. **Apply dotfiles explicitly**:

   ```bash
   chezmoi init --apply <REPO>
   # or, for an existing clone:
   chezmoi apply
   ```

6. **Enable systemd user units (Phase 6 session daemons)** — run inside a graphical or user session so `systemctl --user` works:

   ```bash
   systemctl --user daemon-reload
   systemctl --user enable quickshell.service swaync.service clipboard-history.service \
     swww.service wallpaper-restore.service hypridle.service theme-propagation.service
   # Optional (AGS quarantine): systemctl --user enable ags.service
   # Existing: openclaw-gateway.service, atuin.service, kanshi.service, restic-backup.timer
   ```

   If you are not yet in a user session, run this after first login to Hyprland.

7. **Validate configuration**:

   ```bash
   ~/scripts/validate-configs.sh
   ```

8. **Log into Hyprland**; confirm that the Phase 0 do-not-break list is satisfied (bar, keybinds, launcher, OpenClaw sidebar, etc.). Session daemons (quickshell, swaync, clipboard, wallpaper, hypridle) start via systemd user units bound to `graphical-session.target`.

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

Bootstrap does not change package ownership policy; Arch remains the only package owner at this phase, consistent with Phase 0 decisions.

---

### 4. Fullstack 1–4 execution (short path)

Minimal path to apply config, ensure edition, validate, and confirm the Control Plane hub and glass tokens:

1. **Apply config:** `chezmoi apply` or one-command install via `get.sh` (get.sh runs `sl1c3d-edition set base` if `~/.config/hypr/edition.conf` is missing).
2. **Ensure edition (if not using get.sh):** If `~/.config/hypr/edition.conf` is missing, run `~/.config/SL1C3D-L4BS/bin/sl1c3d-edition set base`. Optionally run `~/.config/SL1C3D-L4BS/system-config/bootstrap.sh --edition base` to install packages and enable services from the edition manifest.
3. **Validate:** `~/scripts/validate-configs.sh` and `~/scripts/run-golden-suite.sh` (or `sl1c3d validate`).
4. **Session check:** Start Hyprland; open the bar logo (Control Plane Hub) and AGS quicksettings (e.g. Super+I) to confirm glass styling and design tokens.

