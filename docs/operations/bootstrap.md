## Bootstrap — First-Time Setup

This bootstrap guide is aligned with:

- Phase 0 inventory and install paths: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (package sources, session targets, UWSM entry): `docs/inventory/phase0-decisions.md`
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

### 2. UWSM Integration (Target Architecture)

Phase 6 has moved durable daemons to systemd user units; the session is still started by the existing login path (e.g. TTY or DM). When UWSM is introduced:

- Install and configure UWSM via Arch packages.  
- Configure the login manager or TTY to use **`uwsm start hyprland.desktop`** as the entry path (per `docs/inventory/phase0-decisions.md`).  
- User units are already enabled as in step 5 above; UWSM will activate `graphical-session.target` and thus start all durable daemons.  
- **dbus-broker** is recommended on Arch with UWSM (Hyprland wiki).

---

### 3. Rollback Considerations

- If a bootstrap attempt introduces instability:
  - Re-run `~/scripts/validate-configs.sh` to confirm config integrity.  
  - Use `chezmoi diff` and VCS history to revert recent changes to the chezmoi source.  
  - Reapply dotfiles only after confirming the rollback steps.

Bootstrap does not change package ownership policy; Arch remains the only package owner at this phase, consistent with Phase 0 decisions.

