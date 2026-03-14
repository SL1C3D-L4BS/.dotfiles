## Ownership Matrix — Artifacts and Sources of Truth

This matrix builds on:

- Phase 0 inventories: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (package sources, theme intent): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions: `docs/inventory/phase0-contradictions.md`

Its goal is to ensure **one artifact, one owner, one path of record**, with phase responsibilities and rollback options made explicit.

---

### 1. Artifact Classes

Key artifact classes (derived from the living stack and the Masterclass plan):

- **Session-core configs:** Hyprland (`hyprland.conf`, `autostart.conf`, `binds.conf`, etc.), systemd user unit files under `~/.config/systemd/user/`.
- **UI support configs:** Quickshell QML, swaync config/style, AGS app and widgets, Ghostty config and themes.
- **Theme data:** QML theme tokens, SCSS variables, Ghostty color schemes, future `theme.tokens.toml` and `~/.config/sl1c3d/theme.json`.
- **Host/system configs:** sysctl, pacman configuration, getty autologin, and related `system-config` artifacts.
- **Toolchain configs:** Yazi, Fuzzel, Zellij, Neovim, Starship, Atuin, fastfetch.
- **Operational scripts:** `~/scripts/validate-configs.sh`, install scripts under `dot_config/SL1C3D-L4BS/system-config/`, bootstrap scripts.

---

### 2. Ownership Table (High-Level)

| Class                   | Owner (Phase 0)          | Target Owner (Masterclass)           | Responsible Phases       | Rollback stance |
|-------------------------|--------------------------|--------------------------------------|--------------------------|-----------------|
| Session-core configs    | chezmoi (`dot_config/`)  | chezmoi (paths may change)          | 1, 6, 7                  | revert to Phase 0 configs from VCS if session refactors regress |
| UI support configs      | chezmoi (`dot_config/`)  | chezmoi                             | 1, 4, 9                  | keep existing QML/SCSS assets for reversion alongside new ones |
| Theme tokens & outputs  | scattered (multi-owner)  | **Repo tokens + generator only**     | 1, 4                     | preserve old theme files to allow switching back if needed |
| Host/system configs     | `system-config/`         | `host/arch/` (single path of record) | 7, 10                    | use migration ledger to move artifacts back if host split misfires |
| Toolchain configs       | chezmoi (`dot_config/`)  | chezmoi                             | 1, 8                     | re-point PATH/package owners back to Arch-only if Nix integration is rolled back |
| Operational scripts     | chezmoi `scripts/`, `system-config/` | chezmoi, host scripts where appropriate | 1, 2, 3, 7 | keep prior scripts in VCS; deprecate instead of deleting |

No Nix process owns files in `$HOME` at Phase 1; Nix will own **packages** only in Phase 8.

---

### 3. Theme Ownership (Forward-Looking)

From Phase 0 contradictions, theme ownership needs consolidation.

**Current state (Phase 0):**

- Multiple theme sources across QML, SCSS, Ghostty, and possibly `.chezmoidata`.

**Target state:**

- **Canonical repo source:** a single theme tokens file (e.g. `theme.tokens.toml` or `.chezmoidata` section).
- **Runtime JSON:** `~/.config/sl1c3d/theme.json` generated exclusively from the canonical repo source.
- **Consumers:** Quickshell, AGS, Hyprland, Ghostty, and other clients read only from the canonical source or its generated outputs.

**Responsible phase:** Phase 4.

**Rollback:**

- Phase 4 must keep the legacy theme assets and a documented switch back to “legacy theme mode” if the generator or token model proves unstable; this document will be updated when that switch mechanism exists.

---

### 4. Package Ownership (Forward-Looking Summary)

Detailed rules live in `docs/architecture/package-ownership.md`. This section asserts:

- Phase 0 package owners are **all Arch-based**, as recorded in `phase0-inventory.md` and `phase0-decisions.md`.
- Nix will own:
  - **Binaries only** (packages, devShells) starting in Phase 8.
  - No configuration files under `$HOME`.

**Responsible phase:** Phase 8.

**Rollback:**

- Remove affected packages from Nix profiles and reinstall them from Arch according to the per-class rules in `package-ownership.md`.

---

### 5. Migration-Capable Areas and Rollback Notes

Every area where ownership can change must include rollback language:

- **Session daemons:** move from Hyprland `exec-once` to systemd user units (Phase 6); rollback by disabling new units and reinstating `autostart.conf` as recorded in Phase 0.
- **Host/system configs:** move from `system-config/` to `host/arch/` (Phase 7 and 10); rollback by reversing the migration ledger entry and reapplying the previous host configuration commands.
- **Package source:** move from Arch-only to a mix of Arch + Nix (Phase 8); rollback by following the documented Arch↔Nix migration and rollback rules.

There are no ownership changes implied by this document alone; it only constrains and records how future phases may shift ownership.

