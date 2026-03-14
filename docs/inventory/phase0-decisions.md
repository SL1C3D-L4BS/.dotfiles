## Phase 0 — Approved Decision Artifacts (Binding Inputs)

These decisions are **binding implementation inputs** for later phases (especially Phases 2, 4, 6, 7, 8, and 10). They are based on the live repo + runtime inspection at the time of Phase 0 and should not be silently changed without updating this document and the migration ledger.

---

### 1. Exact Session Targets

The user systemd instance currently exposes the following relevant session targets:

- `graphical-session-pre.target`
- `graphical-session.target`
- `xdg-desktop-autostart.target`
- `default.target`

**Binding decision:**

- **Primary session anchor:** `graphical-session.target`
- **Pre-session anchor for environment and sockets:** `graphical-session-pre.target`
- **Autostart compatibility target:** `xdg-desktop-autostart.target`

All future user units that represent durable session daemons (quickshell, swaync, clipboard history, wallpaper restore, hypridle, theme propagation, OpenClaw gateway wrappers) must bind to these exact names via `WantedBy=` / `After=` / `Wants=`; no alternative or placeholder targets are to be introduced without updating this section.

---

### 2. Session Entry Path (TTY-Only, No UWSM)

**Binding decision:** Session is **TTY-only**; UWSM is **out of scope**. No display manager; no UWSM.

- **Entry path:** User logs in on TTY (e.g. getty autologin on TTY1); Hyprland is started directly (e.g. from `.xinitrc`-style or direct `Hyprland` exec). Session entry is **not** `uwsm start hyprland.desktop` — UWSM is not used.
- **Environment export:** `autostart.conf` continues to run `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland` and portal start; no separate "finalize" step. Session daemons are started from `autostart.conf` via `systemctl --user start …` for the durable-daemon set, because on TTY login `graphical-session.target` is not automatically activated.

All documentation and Phase 6 implementation assume this TTY-only, no-UWSM model.

---

### 3. (Reserved — Formerly uwsm finalize)

Not used. Environment export is handled in `autostart.conf` as in §2. No UWSM; no finalize step.

---
---

### 4. Exact Durable-Daemon Migration Set

The following daemons are currently launched as Hyprland `exec-once` children but are expected to become durable user services under systemd (bound to `graphical-session.target`):

- `quickshell` (bar)
- `swaync` (notifications)
- `wl-paste --watch cliphist store` (clipboard history)
- `swww-daemon` + `waypaper --restore` (wallpaper daemon + restore)
- `hypridle` (idle + lock orchestration)
- `ags` (quicksettings panel UI)
- `xdg-desktop-portal-hyprland` / `xdg-desktop-portal` starter logic

Existing user units already present and relevant:

- `openclaw-gateway.service` (enabled, systemd-managed).
- `atuin.service`, `kanshi.service`, `restic-backup.service` (configured under chezmoi).

**Binding decision (durable-daemon migration set):**

- **Must be systemd user units (no longer `exec-once` in steady state):**
  - `quickshell`
  - `swaync`
  - `wl-paste --watch cliphist store` (as a dedicated clipboard-history service)
  - `swww-daemon` + wallpaper restore (combined wallpaper service)
  - `hypridle`
  - `ags` (if retained under the AGS quarantine rules)
  - Portal bootstrap (a service that ensures XDG portals are active without relying on sleeps).
- **Remain systemd user units (already correct owner):**
  - `openclaw-gateway.service`
  - `atuin.service`
  - `kanshi.service`
  - `restic-backup.service` (+ timer)

Later phases must implement these as user units with explicit `Type`, `WantedBy`, `After`, `Wants`, restart policies, and mapped **doctor severity** (fatal / degraded / informational).

---

### 5. Exact CI Render Target Set

Phase 0 must lock in the minimum render targets that CI will treat as non-optional. These inform `ci/render-sanity.sh` in Phase 2.

**Binding render target set (minimum viable, headless-safe):**

1. **Hyprland core config render:**
   - Template → `~/.config/hypr/hyprland.conf` equivalent from chezmoi.
   - CI check: render succeeds with no unresolved variables and produces deterministic output.
2. **Quickshell theme fragment:**
   - QML fragment (e.g. `Bar.qml` + `BrandTheme.qml`) rendered from the current templates.
   - CI check: tokens resolve; required bindings present; no missing keys.
3. **AGS token/theme output:**
   - TypeScript/SCSS compilation step that produces the AGS theme artifacts (or, at minimum, validates that the TypeScript + SCSS compile with all tokens present).
4. **Starship prompt config:**
   - Render and validate the Starship TOML (or JSON) for the `brand` palette.
5. **Canonical runtime theme artifact (future `~/.config/sl1c3d/theme.json`):**
   - Even before Phase 4 formalizes it, this file is reserved as the **single runtime theme JSON** and must become a render target once the generator is introduced.

**CI gate rules (binding for `render-sanity`):**

- Each target **must exist** at render time.
- Render commands **must exit 0**.
- **No unresolved template variables** or missing data keys.
- Required outputs **must not be empty**.
- Output paths must be **deterministic** and recorded in docs.

---

### 6. Exact Ambiguous Package-Source Decisions

Many tools can be installed either via Arch (pacman/AUR) or Nix. At Phase 0, there is **no Nix flake or `nix/` directory**; all installs are Arch-hosted.

**Binding decision for Phase 0 (until Phase 8):**

- **Session core (Hyprland, Wayland portals, PipeWire stack):**
  - **Source:** Arch (pacman/AUR).
  - Rationale: tightly coupled to host and display stack; easier debug and alignment with Arch wiki guidance.
- **UI support (quickshell, swaync, Ghostty, Yazi, Fuzzel, Mako, Waypaper, AGS):**
  - **Source:** Arch (pacman/AUR) for now.
  - Nix migration is permitted later on a per-package-class basis, but **Phase 8 must explicitly log each migration** in `package-ownership.md` and the migration ledger.
- **Toolchain (ripgrep, bat, eza, fd, zoxide, fzf, git-related tools), languages (Node, Python, Go, Rust), operator/diagnostic tools, theme tooling:**
  - **Source at Phase 0:** Arch (pacman/AUR) via `system-config` install scripts.
  - **Future intent:** these are the primary candidates for Nix ownership in Phase 8, but **until that phase is executed, Arch is the canonical package source.**

**Ambiguous package-source decision rule (binding):**

- When Phase 8 introduces Nix, **no package may silently change owner** from Arch to Nix (or vice versa).
- For any package that exists in both worlds, the default at Phase 0 is:
  - **Owner = Arch packages**, as configured today.
  - Any migration must:
    - Update `docs/architecture/package-ownership.md`.
    - Record the move (and rollback path) in the migration ledger.
    - Update bootstrap/install scripts so there is a single path of record.

This ensures that Phase 8 has **no “open questions”** about current package ownership; it starts from a clearly documented **Arch-first** baseline.

