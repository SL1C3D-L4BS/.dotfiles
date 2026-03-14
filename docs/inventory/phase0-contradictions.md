## Phase 0 — Contradictions & Tensions in Live Repo

This document records contradictions between the **current live behavior** and the **Masterclass target architecture (IDs 008–011)**. These are not fixed in Phase 0; they are inputs to later phases with explicit migration and rollback notes.

---

### 1. Session Management: `exec-once` vs UWSM + systemd Units

- **Observed:**
  - Hyprland `autostart.conf` launches most durable daemons via `exec-once`:
    - `quickshell`, `swaync`, `wl-paste --watch cliphist store`, `swww-daemon`, `waypaper --restore`, `hypridle`, `ags`, XDG portals starter, `hyprsunset`, and `chezmoi apply`.
  - Startup sequencing relies on `sleep` calls (1–3 seconds) instead of explicit unit ordering.
  - UWSM (`uwsm`) is not installed.
- **Target (Masterclass):**
  - UWSM-managed session with durable daemons as systemd user units bound to `graphical-session.target`, minimal `exec-once`, and no sleep-based sequencing.
- **Contradiction:**
  - The current system violates the “minimal `exec-once` / systemd-owned daemons” model and has no UWSM presence yet.

---

### 2. `chezmoi apply` on Login

- **Observed:**
  - `autostart.conf` runs:

    ```ini
    exec-once = chezmoi apply
    ```

  - This makes every session start implicitly mutate the home directory and configs.
- **Target (Masterclass):**
  - **No `chezmoi apply` on login or session startup.**
  - Chezmoi apply is restricted to explicit operator flows (`sl1c3d repair --apply`, bootstrap, manual runs).
- **Contradiction:**
  - Current behavior directly conflicts with the Masterclass requirement and increases risk during login.

---

### 3. Theme Source-of-Truth vs Scattered Theme Artifacts

- **Observed:**
  - Theme data is scattered across:
    - QML (`BrandTheme.qml`).
    - SCSS for Quickshell and AGS.
    - Ghostty theme files.
    - Possibly `.chezmoidata` and other templates.
  - There is no single canonical `theme.tokens.toml` or equivalent file documented as the unique token source.
- **Target (Masterclass):**
  - **One canonical theme source in the repo** (tokens file or `.chezmoidata` section).
  - Generated runtime theme JSON (`~/.config/sl1c3d/theme.json`) as Layer B.
  - All consumers (QML, SCSS, Hyprland, Ghostty) as Layer C outputs from a single generator.
- **Contradiction:**
  - The current stack does not yet enforce a canonical theme token source or a single authoritative generator.

---

### 4. Docs Location vs Repo-Only Architecture Docs

- **Observed:**
  - Existing documentation under `dot_config/SL1C3D-L4BS/docs/` lives inside the chezmoi-managed `dot_config` tree and is deployed into `$HOME` with the rest of `dot_config`.
- **Target (Masterclass):**
  - A **top-level `docs/` directory** at repo root, explicitly **not** deployed via chezmoi.
  - Docs are repo-only; runtime machines read them via README, CLI help, or external viewers.
- **Contradiction:**
  - Current docs live in a path that is treated as runtime config, not as pure repo-only documentation.

---

### 5. Package Ownership vs Future Nix Integration

- **Observed:**
  - All packages (including those that are strong candidates for Nix ownership, such as Neovim, LSPs, dev tools) are installed via Arch (pacman/AUR), often via `system-config` scripts.
  - There is currently no `nix/` directory, flake, or documented package-ownership policy.
- **Target (Masterclass):**
  - Nix Mode A in Phase 8: flakes + packages + devShells only (no Home Manager) with **package-ownership rules** and migration ledger.
- **Contradiction:**
  - The repo is not yet prepared for Nix integration; package sources are implicit and concentrated in Arch scripts, with no class-based ownership mapping.

---

### 6. AGS Role vs Quickshell Strategy

- **Observed:**
  - AGS is actively used (quicksettings panel via Hyprland autostart and binds).
  - Quickshell is the primary bar and UI surface.
- **Target (Masterclass):**
  - **Quickshell = strategic framework**, **AGS = quarantined** with explicit keep/migrate/delete decisions and deadlines per component.
- **Contradiction:**
  - There is no current AGS quarantine, decision matrix, or migration timeline; AGS effectively coexists as a first-class citizen.

---

### 7. Lack of Formal Migration Ledger

- **Observed:**
  - Host- and system-config-related files live under `dot_config/SL1C3D-L4BS/system-config/` with no `host/arch/` directory at repo root.
  - There is no central migration ledger mapping “current path → target path → owner → rollback”.
- **Target (Masterclass):**
  - `host/arch/` as the single path of record.
  - `docs/architecture/migration-ledger.md` tracking all migrations.
- **Contradiction:**
  - The repo currently has **no explicit migration ledger** and no `host/arch/` scaffold, so selective migrations could become silent duplication without corrective work in later phases.

---

### 8. UWSM Absence vs UWSM-First Design

- **Observed:**
  - UWSM (`uwsm`) is not installed.
  - Session management and environment export rely on Hyprland `exec-once` and `dbus-update-activation-environment`.
- **Target (Masterclass):**
  - UWSM as first-class session architecture, owning session entry and environment initialization.
- **Contradiction:**
  - The live system operates on a non-UWSM session model while the plan assumes UWSM as the end-state authority.

---

These contradictions are **expected** at Phase 0. They provide the concrete gap analysis that Phase 1–10 must close, with each migration recorded in the future architecture docs, migration ledger, and package-ownership definitions.

