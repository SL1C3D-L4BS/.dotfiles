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

### 2. Exact UWSM Entry Path

UWSM (`uwsm`) is **not installed** in the live environment at Phase 0 (`command -v uwsm` fails), but the Masterclass plan requires UWSM as the target session orchestrator.

**Binding decision (target architecture for Phase 6):**

- **TTY entry path (primary):**
  - `uwsm start hyprland.desktop`
- **Display-manager (DM) entry path (when present):**
  - UWSM-managed desktop entry for Hyprland, equivalent to the above command.

This makes **`uwsm start hyprland.desktop`** the **single canonical UWSM entry path** for future configuration and documentation, regardless of the current (non-UWSM) login mechanism.

---

### 3. Exact `uwsm finalize` Decision

Phase 0 must decide whether explicit `uwsm finalize` handling will be required in this stack.

Observed behavior:

- `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland` is currently used in `autostart.conf` to push Wayland/session environment into user systemd.
- UWSM is not yet installed, so there is no live `uwsm finalize` behavior to inspect.

**Binding decision (for target UWSM architecture):**

- **`uwsm finalize` is required.**
- **Placement:** after the compositor is ready, bound to the `graphical-session-pre.target`/`graphical-session.target` transition. In practice:
  - UWSM will manage exporting the Wayland environment; `autostart.conf` must eventually stop calling `dbus-update-activation-environment` directly.
  - Any explicit finalize hook (if UWSM requires one in this configuration) must be documented under the boot/session lifecycle docs in Phase 1 and wired as a **systemd user unit** or UWSM hook, not as a bare `exec-once`.

Until UWSM is installed and configured, this remains a **forward-looking binding**: future implementation work must either (a) confirm that UWSM supersedes manual env export and document “no explicit `uwsm finalize` needed” while keeping this section updated, or (b) implement and document an explicit finalize step consistent with this decision.

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

- **Session core (Hyprland, UWSM once introduced, Wayland portals, PipeWire stack):**
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

