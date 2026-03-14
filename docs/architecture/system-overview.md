## System Overview — SL1C3D-L4BS Masterclass

This overview is grounded in the Phase 0 inventories and decisions:

- Runtime and config state: `docs/inventory/phase0-inventory.md`
- Approved decision artifacts: `docs/inventory/phase0-decisions.md`
- Baseline benchmarks: `docs/inventory/phase0-benchmarks.md`
- Do-not-break list: `docs/inventory/phase0-do-not-break.md`
- Identified contradictions: `docs/inventory/phase0-contradictions.md`

No behavior changes are introduced here; this document describes the **target architecture** and maps each target to a responsible phase with rollback notes.

---

### 0. Five-Part Stack (Canonical)

The masterclass system is exactly five parts:

| Part | Role | Owner |
|------|------|--------|
| **Host** | Kernel, base system, system packages | **Arch Linux (linux-zen)** — pacman/AUR |
| **Session** | TTY autologin + systemd user units (Hyprland, bar, notifications, etc.) | **systemd user** + minimal Hyprland exec-once |
| **Packages / devShells** | User toolchain, languages, LSPs, formatters, linters, dev environments | **Nix** (flake + profile + devShells) |
| **Config / state** | Dotfiles, app config, theme state, generated state | **Chezmoi** (source `~/.local/share/chezmoi`) |
| **Operations** | Doctor, validate, repair, benchmark, theme, edition, bootstrap, session | **sl1c3d** CLI |

- **Host:** Arch/linux-zen; pacman owns session-core (Hyprland, PipeWire, portals, etc.) and host packages only.
- **Session:** TTY-only; no display manager; durable daemons as systemd user units started from autostart.
- **Nix:** All user-facing toolchain, languages, LSPs, formatters, linters, and `nix develop` shells. Configs remain in chezmoi.
- **Chezmoi:** All config and state; no package installation (except via scripts that call pacman or Nix).
- **sl1c3d:** Single operations surface; no ad-hoc scripts for health or apply.

---

### 1. Layers and Ownership

Based on the Phase 0 inventories and the five-part stack above:

- **Host OS (Arch Linux / linux-zen)**  
  - Kernel: linux-zen. Package manager: pacman/AUR.  
  - Owns **host** and **session-core** only (Hyprland, PipeWire, XDG portals, TTY/session components).  
  - **Nix** owns user packages, toolchain, languages, LSPs, formatters, devShells (see below).  
  - **Rollback:** uninstall Nix-provided packages and restore pacman/AUR per `docs/architecture/package-ownership.md` and migration ledger.

- **Display & Audio stack**  
  - Hyprland compositor, PipeWire, WirePlumber, XDG Portals, dbus-broker/user D-Bus.  
  - **Session targets:** `graphical-session-pre.target`, `graphical-session.target`, `xdg-desktop-autostart.target` (Phase 0 exact session targets).  
  - **Migration-capable:** yes (revised user units; TTY-only, no UWSM).  
  - **Responsible phase:** Phase 6 (systemd session).  
  - **Rollback:** revert unit changes and re-enable the previous Hyprland `exec-once`-based startup sequence recorded in Phase 0 inventory.

- **Packages and devShells (Nix)**  
  - **Nix** owns user toolchain, languages, LSPs, formatters, linters; `nix profile install .#default` and `nix develop` (see `nix/`).  
  - Configs for Nix-provided tools remain in **chezmoi**; Nix supplies binaries only.  
  - PATH: Nix profile before `/usr/bin` so Nix wins for toolchain/languages.  
  - **Rollback:** `nix profile uninstall` and reinstall via pacman/AUR per package-inventory.md.

- **Configuration and state (chezmoi)**  
  - Source-of-truth repo at `~/.local/share/chezmoi`. Owns all **config and state** (`dot_config/**`, scripts, theme tokens, generated state).  
  - Does not install packages; bootstrap scripts invoke pacman or Nix.  
  - **Rollback:** restore chezmoi source from VCS and re-run `chezmoi apply`.

- **Operations (`sl1c3d` CLI)**  
  - Single entrypoint: doctor, validate, repair, benchmark, theme, edition, bootstrap, session.  
  - **Responsible phase:** Phase 3.  
  - **Rollback:** retain underlying scripts; sl1c3d is a thin orchestrator.

- **Theme system**  
  - Today: scattered QML, SCSS, Ghostty themes (see Phase 0 contradictions).  
  - Target: three-layer theme with canonical repo tokens and generated runtime JSON at `~/.config/sl1c3d/theme.json` (Phase 0 decision).  
  - **Migration-capable:** yes (consolidation and generator introduction).  
  - **Responsible phase:** Phase 4 (theme source-of-truth redesign).  
  - **Rollback:** keep legacy theme fragments in VCS; Phase 4 must allow toggling back to the pre-generator theme paths using the migration ledger.

- **Validation and CI**  
  - Today: `~/scripts/validate-configs.sh` only (Phase 0 benchmarks).  
  - Target: three-layer checks (lint/doctor/validate) plus CI headless `render-sanity` (fixed render targets per Phase 0 decisions).  
  - **Migration-capable:** yes (CI scaffolding, new scripts).  
  - **Responsible phases:** Phase 2 (CI foundation) and Phase 3 (doctor/validate wiring).  
  - **Rollback:** disable new CI jobs or scripts while keeping `validate-configs.sh` intact as a known-good baseline.

---

### 2. Session Model: Current vs Target

From `phase0-inventory.md`, the current session model is:

- Hyprland launches, then `autostart.conf` starts all durable daemons via `exec-once`, with multiple `sleep`-based delays.
- `chezmoi apply` runs on each login.
- `dbus-update-activation-environment` exports `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP=Hyprland` into user systemd.

From `phase0-decisions.md`, the target session model is:

- **TTY-only session** (no UWSM; no display manager). User logs in on TTY; Hyprland starts directly.
- **Environment export** in `autostart.conf`: `dbus-update-activation-environment` and portal start; then `systemctl --user start` for the durable-daemon set (because on TTY login `graphical-session.target` is not auto-activated).
- **Durable daemons** as systemd user units (quickshell, swaync, clipboard, wallpaper, hypridle, theme propagation, etc.); started from autostart or bound to `graphical-session.target` where applicable.
- **No `chezmoi apply` at login**; apply occurs only via explicit operator flows.

**Migration-capable:** yes — implemented in Phase 6.

- **Responsible phase:** Phase 6.  
- **Rollback:** disable or mask new user units and restore the previous `autostart.conf` from version control; the do-not-break list ensures Hyprland login and bar remain functional.

---

### 3. Documentation Scope and Deployment

Phase 0 contradictions highlighted that:

- Existing docs under `dot_config/SL1C3D-L4BS/docs/` are deployed into `$HOME`.

Phase 1 corrects this by introducing a **top-level `docs/` directory in the repo** that:

- Lives under `~/.local/share/chezmoi/docs/`.
- Is **ignored by chezmoi** (see `.chezmoiignore` update) and therefore **never deployed into `$HOME`**.

**Migration-capable:** yes (docs layout and how they are referenced can change).

- **Responsible phase:** Phase 1.  
- **Rollback:** remove or rename the new `docs/` directory and restore any prior documentation usage patterns; no runtime behavior depends on these files.

---

### 4. Phase Mapping for Major Targets

Every major architectural target from the Masterclass plan is mapped to a phase and a rollback stance:

- **TTY-only session with systemd user units** (no UWSM)  
  - Phase 6; rollback by restoring Phase 0 `autostart.conf` and disabling new units.

- **Theme three-layer model with canonical repo tokens and single generator**  
  - Phase 4; rollback by reusing legacy QML/SCSS/Ghostty theme files (kept in VCS) if the generator fails, without deleting old assets.

- **Nix Mode A (flakes + packages + devShells only)**  
  - Phase 8; rollback by uninstalling Nix-provided package sets and reinstating Arch ownership according to `docs/architecture/package-ownership.md`.

- **AGS quarantine with keep/migrate/delete per component**  
  - Phase 9; rollback by treating AGS as “kept” for the components in question and recording that decision with owner + milestone in `docs/design-system/components.md`.

- **Physical refactors (host/arch, tools/, etc.)**  
  - Phase 7 and Phase 10; rollback via the before/after/ownership/command proofs required in Phase 10 and the migration ledger in `docs/architecture/migration-ledger.md`.

- **Host and system-config mapping (Phase 7)**  
  - Top-level `host/arch/` is the **single path of record** for Arch-host configuration (packages, boot, sysctl, systemd, bootstrap).  
  - `dot_config/SL1C3D-L4BS/system-config/` is **transitional**; each host/arch subdir either contains a real artifact or a migration note pointing to the current live artifact in system-config.  
  - No duplicate logic: selective migration with ledger entries only. See `docs/architecture/migration-ledger.md` and `host/arch/README.md`.

No target or migration claim in this document is left without a responsible phase and an identified rollback mechanism.

