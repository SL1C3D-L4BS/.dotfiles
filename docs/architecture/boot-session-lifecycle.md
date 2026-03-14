## Boot & Session Lifecycle — SL1C3D-L4BS

This lifecycle description is anchored in:

- Phase 0 runtime inventory: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (session targets, TTY-only, durable-daemon set): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions: `docs/inventory/phase0-contradictions.md`

---

### 1. Current Lifecycle (Phase 0 Snapshot)

From the Phase 0 inventory:

1. **System boot** to Arch Linux; system services (PipeWire, dbus-broker, etc.) start.
2. **User login** via display manager or TTY, launching a Hyprland session.
3. **Hyprland config load** (`hyprland.conf`, `general.conf`, `monitors.conf`, etc.).
4. **Hyprland autostart** runs, launching:
   - `chezmoi apply`
   - `hyprpolkitagent`
   - `gnome-keyring-daemon` (secrets, PKCS#11, SSH)
   - `dbus-update-activation-environment` and portal starters
   - `swww-daemon` + `waypaper --restore`
   - `quickshell`, `ags`, `swaync`, `wl-paste --watch cliphist store`, `hypridle`, `hyprsunset`
   - several `sleep` delays to sequence startup.

This model is **Hyprland-centric** and relies on compositor-child processes and time-based ordering.

---

### 2. Target Lifecycle (TTY-Only, systemd User Units)

Using the binding decisions from Phase 0 (TTY-only; no UWSM):

- **Session targets:**  
  - `graphical-session-pre.target`  
  - `graphical-session.target`  
  - `xdg-desktop-autostart.target`

- **Session entry:** TTY-only. User logs in on TTY (e.g. getty autologin); Hyprland is started directly. No display manager; no UWSM.

The **target lifecycle** after Phase 6 is:

1. **System boot** as today (Arch, systemd, PipeWire).
2. **TTY login**: User logs in on TTY; Hyprland is started directly (e.g. from shell or autologin).
3. **Hyprland starts**; `autostart.conf` runs:
   - Polkit agent, gnome-keyring, `dbus-update-activation-environment` and portal start (environment export).
   - `systemctl --user start` for the durable-daemon set (quickshell, swaync, clipboard-history, swww, wallpaper-restore, hypridle, theme-propagation), because on TTY login `graphical-session.target` is not automatically activated.
   - One-shot hyprsunset (blue-light).
4. **Durable daemons** run as systemd user units; they are started explicitly from autostart. No long-running daemons as compositor children except the minimal glue above.
5. **Autostart compatibility**: XDG autostart entries remain via `xdg-desktop-autostart.target` where applicable.

---

### 3. Lifecycle Rules (Non-Negotiable)

Grounded in Phase 0 and the Masterclass plan:

- **No GUI daemon before session environment is ready.**  
  - Environment export to systemd must be complete before durable session daemons start.  
  - On TTY, environment export is done in `autostart.conf` before starting user units.

- **Minimal `exec-once`.**  
  - Compositor `exec-once` remains for:
    - One-shot utilities (e.g. `hyprsunset` temperature set, if not expressed as a unit).  
    - Very thin glue where a systemd unit is not appropriate.  
  - Long-running daemons must be moved into user units (durable-daemon migration set from `phase0-decisions.md`).

- **No `chezmoi apply` on login.**  
  - Login and session startup must not apply dotfiles.  
  - Chezmoi apply is reserved for operator actions (Phase 3 repair/bootstraps) and manual usage.

---

### 4. Phase Responsibilities and Rollback

- **Phase 6 — systemd session (TTY-only, no UWSM)**
  - Creates and enables user units for the durable-daemon migration set; they are started from `autostart.conf` via `systemctl --user start` (TTY does not activate `graphical-session.target` automatically).
  - Removes `exec-once = chezmoi apply`; keeps minimal exec-once (polkit, keyring, env export, portal start, unit starts, hyprsunset).
  - **Rollback:**  
    - Disable or mask new user units.  
    - Restore the Phase 0 `autostart.conf` from version control.

- **Phase 1 — Documentation only (this document)**
  - No lifecycle behavior is changed in this phase.  
  - Rollback is trivial: delete or adjust this document; runtime remains as in Phase 0.

No other phases are authorized to adjust the boot/session lifecycle without explicitly referencing this document and the Phase 0 decision artifacts.

