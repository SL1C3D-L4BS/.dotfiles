## Service Dependency Graph — Session & Daemons

This document formalizes service dependencies using:

- Phase 0 runtime inventory: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (session targets, durable-daemon set, TTY-only): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions: `docs/inventory/phase0-contradictions.md`

It is descriptive for Phase 1 and binding for later phases.

---

### 1. Session Targets and Anchors

From the Phase 0 decisions:

- **Primary session target:** `graphical-session.target`
- **Pre-session target:** `graphical-session-pre.target`
- **Autostart target:** `xdg-desktop-autostart.target`

All future user units for durable daemons must:

- Use `WantedBy=graphical-session.target` or `WantedBy=graphical-session-pre.target` where appropriate.
- Express ordering via `After=` and `Wants=` relationships using **these exact target names**.

---

### 2. Durable-Daemon Migration Set (Target Units)

Based on the Phase 0 durable-daemon migration set:

- `quickshell` → `quickshell.service`
- `swaync` → `swaync.service`
- Clipboard history → `clipboard-history.service` (wraps `wl-paste --watch cliphist store`)
- Wallpaper → `wallpaper-restore.service` (wraps `swww-daemon` + `waypaper --restore`)
- `hypridle` → `hypridle.service`
- `ags` (if kept) → `ags.service`
- Portal bootstrap → `xdg-portals-bootstrap.service` (ensures XDG portals active without sleep-based commands)

Existing units (Phase 0 inventory):

- `openclaw-gateway.service`
- `atuin.service`
- `kanshi.service`
- `restic-backup.service` (+ timer)

Phase 6 implementation: units under `dot_config/systemd/user/` with exact `[Unit]`/`[Service]` entries. Per-unit semantics (unit type, enable default, restart policy, doctor severity) are documented below.

**Session entry (Phase 0 binding):** TTY-only; no UWSM. User logs in on TTY; Hyprland starts directly. Session daemons are started from `autostart.conf` via `systemctl --user start` for the durable-daemon set.

---

### 3. Target Dependency Graph (Conceptual)

High-level dependencies, all in the **user** systemd scope:

- `graphical-session-pre.target`
  - Prepares environment and sockets for the session.
  - **Dependencies (Wants/After):**
    - Environment export (handled in autostart.conf on TTY).

- `graphical-session.target`
  - Main anchor for session daemons.
  - **Wants/After edges (target model):**
    - `quickshell.service`
    - `swaync.service`
    - `clipboard-history.service`
    - `wallpaper-restore.service`
    - `hypridle.service`
    - `ags.service` (if retained)
    - `xdg-portals-bootstrap.service`
    - `openclaw-gateway.service` (if configured as session-scoped rather than always-on)

- `xdg-desktop-autostart.target`
  - Provides compatibility for XDG `.desktop` autostart entries.
  - Can depend on `graphical-session-pre.target` to ensure environment readiness.

**Migration-capable:** yes — the graph expresses how units will eventually be wired; concrete units come in Phase 6.

- **Responsible phase:** Phase 6 (unit creation and wiring).  
- **Rollback:** keep current `exec-once`-based graph from Phase 0 inventory as a fallback; disabling new units and re-enabling `autostart.conf` entries reverts to previous semantics.

---

### 3.1. Per-Unit Semantics (Phase 6 Implementation)

| Unit | Type | Enable default | Restart | Ordering | Doctor severity |
|------|------|----------------|---------|----------|-----------------|
| quickshell.service | simple | enabled | on-failure | After=graphical-session.target | fatal |
| swaync.service | simple | enabled | on-failure | After=graphical-session.target | degraded |
| clipboard-history.service | simple | enabled | on-failure | After=graphical-session.target | degraded |
| swww.service | simple | enabled | on-failure | After=graphical-session.target | degraded |
| wallpaper-restore.service | oneshot | enabled | — | After=swww.service | degraded |
| hypridle.service | simple | enabled | on-failure | After=graphical-session.target | degraded |
| ags.service | simple | enabled | on-failure | After=graphical-session.target | informational |
| openclaw-gateway.service | simple | enabled | on-failure | (existing) | degraded |
| theme-propagation.service | oneshot | enabled | — | After=graphical-session.target | degraded |

All session daemon units use `PartOf=graphical-session.target` and `WantedBy=graphical-session.target` so they start with the session and stop when it ends. Portal startup remains in Hyprland `exec-once` (dbus-update-activation-environment + `systemctl --user start xdg-desktop-portal-hyprland xdg-desktop-portal`) until a dedicated portal-bootstrap unit is introduced.

**D-Bus:** Ensure no durable daemon is launched as a child of the compositor; they run as user units. On Arch, `dbus-broker` is optional.

---

### 4. Doctor Severity Mapping (Preview for Phase 3)

While implementation belongs to Phase 3 (doctor CLI) and Phase 6 (units), this document records **intended severity** for each service:

- **Fatal (session cannot meet do-not-break list):**
  - `quickshell.service` (bar missing).
  - `swaync.service` (if notifications are part of mandatory workflow).
  - `xdg-portals-bootstrap.service` (if its failure blocks key user flows such as screenshare and file pickers).

- **Degraded (session usable but impaired):**
  - `clipboard-history.service`
  - `wallpaper-restore.service`
  - `ags.service` (if retained while under quarantine).
  - `openclaw-gateway.service` (AI sidebar unavailable but desktop still runs).

- **Informational (optional enhancements):**
  - Units tied only to optional visuals or diagnostics where absence does not violate the Phase 0 do-not-break list.

**Migration-capable:** yes — severity levels can be reclassified as experience and requirements evolve.

- **Responsible phases:** Phase 3 (exposes severities via `sl1c3d doctor`) and Phase 6 (connects units to doctor checks).  
- **Rollback:** maintain the current `validate-configs.sh` behavior and log-only status outputs if severity enforcement proves too strict; this does not change the baseline config validation.

No placeholders are used here; any future change in severity mapping must update this document and the doctor implementation together.

