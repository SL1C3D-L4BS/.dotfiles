## Boot & Session Lifecycle — SL1C3D-L4BS

This lifecycle description is anchored in:

- Phase 0 runtime inventory: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (session targets, UWSM entry, finalize decision, durable-daemon set): `docs/inventory/phase0-decisions.md`
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

### 2. Target Lifecycle (UWSM + systemd User Targets)

Using the binding decisions from Phase 0:

- **Session targets:**  
  - `graphical-session-pre.target`  
  - `graphical-session.target`  
  - `xdg-desktop-autostart.target`

- **UWSM entry path:** `uwsm start hyprland.desktop`

- **`uwsm finalize` decision:** finalize is required in the target model; environment export must be owned by UWSM and systemd rather than by `exec-once` calls.

The **target lifecycle** after Phase 6 is:

1. **System boot** as today (Arch, systemd, PipeWire, dbus-broker).
2. **UWSM-managed login**:
   - Display manager or TTY runs `uwsm start hyprland.desktop`.
   - UWSM prepares the user session environment and activates the correct systemd user targets.
3. **User systemd enters `graphical-session-pre.target`**:
   - Environment and socket-related hooks run here (including any UWSM finalize logic that needs a pre-session anchor).
4. **Hyprland starts under UWSM**:
   - Hyprland no longer owns long-running daemons via `exec-once` except minimal glue or one-shot utilities.
5. **User systemd enters `graphical-session.target`**:
   - Durable user services (quickshell, swaync, clipboard history, wallpaper restore, hypridle, AGS if kept, portal bootstrap) are started as systemd user units, using `After=` and `Wants=` to express dependencies.
6. **Autostart compatibility**:
   - Any remaining XDG autostart entries are managed via `xdg-desktop-autostart.target` rather than via Hyprland `exec-once`.

---

### 3. Lifecycle Rules (Non-Negotiable)

Grounded in Phase 0 and the Masterclass plan:

- **No GUI daemon before session environment is ready.**  
  - Environment export to systemd must be complete before durable session daemons start.  
  - In the UWSM model, this is expressed via `graphical-session-pre.target` and `uwsm finalize`.

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

- **Phase 6 — UWSM + systemd migration**
  - Introduces UWSM and rewires the lifecycle from Hyprland-centric to target-session-centric.
  - Creates and enables user units for the durable-daemon migration set, bound to `graphical-session.target` and `graphical-session-pre.target`.
  - Removes `exec-once = chezmoi apply` and durable-daemon `exec-once` lines from `autostart.conf`.
  - **Rollback:**  
    - Disable or mask new user units.  
    - Restore the Phase 0 `autostart.conf` from version control.  
    - Re-enable previous behavior while keeping the new units present but inactive for future testing.

- **Phase 1 — Documentation only (this document)**
  - No lifecycle behavior is changed in this phase.  
  - Rollback is trivial: delete or adjust this document; runtime remains as in Phase 0.

No other phases are authorized to adjust the boot/session lifecycle without explicitly referencing this document and the Phase 0 decision artifacts.

