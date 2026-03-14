## Phase 0 — Contradictions & Tensions in Live Repo

This document records contradictions between the **current live behavior** and the **Masterclass target architecture (IDs 008–011)**. These are not fixed in Phase 0; they are inputs to later phases with explicit migration and rollback notes.

---

### 1. Session Management — RESOLVED (Phase 6, TTY-only)

- **Target (Masterclass, updated):** TTY-only session; no UWSM. Durable daemons as systemd user units; started from `autostart.conf` via `systemctl --user start`. Minimal exec-once. No `chezmoi apply` on login.
- **Status:** Implemented. See `autostart.conf` and `dot_config/systemd/user/*.service`.

---

### 2. `chezmoi apply` on Login — RESOLVED

- **Target:** No `chezmoi apply` on login; explicit operator flows only.
- **Status:** Resolved. `autostart.conf` no longer runs `chezmoi apply`.

---

### 3. Theme Source-of-Truth — RESOLVED (Phase 4)

- **Target:** One canonical `theme.tokens.toml`; generated `~/.config/sl1c3d/theme.json`; single generator via `sl1c3d theme apply`.
- **Status:** Resolved. See `theme.tokens.toml`, `dot_config/SL1C3D-L4BS/theme/generate.py`, and design-system docs.

---

### 4. Docs Location — RESOLVED (Phase 1)

- **Target:** Top-level `docs/` repo-only; not deployed via chezmoi.
- **Status:** Resolved. `docs/` exists at repo root and is in `.chezmoiignore`.

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

### 8. UWSM — RESOLVED (Out of Scope)

- **Decision:** UWSM is **out of scope**. Session is **TTY-only**; no display manager; no UWSM. Environment export and session daemon startup are handled in `autostart.conf` as documented in `phase0-decisions.md` §2.
- **Status:** No contradiction; architecture is TTY-only by design.

---

Remaining contradictions (5–7) are intentional gaps closed in later phases (Nix, AGS quarantine, migration ledger). Resolved items (1–4, 8) reflect current implemented state.

