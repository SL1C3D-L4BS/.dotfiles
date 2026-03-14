## Migration Ledger — Host, Session, and Config Moves

This ledger is the single place to record migrations between paths and owners. It is founded on:

- Phase 0 inventory: `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (durable-daemon set, package-source decisions): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions: `docs/inventory/phase0-contradictions.md`
- **Package-level map:** `docs/architecture/package-inventory.md` — per-package table (doc class, current/target owner, config paths, rollback) for every tool in the stack; use for Phase 8 package migrations.

At Phase 1, it contains **no executed migrations**; it documents the structure and expected fields for future entries.

---

### 1. Ledger Fields

Each migration entry must capture:

- **Artifact ID:** a short stable identifier (e.g. `host-sysctl-performance`, `daemon-quickshell`, `pkg-neovim`).
- **Current path:** where the artifact lives today (e.g. `dot_config/SL1C3D-L4BS/system-config/sysctl.d/99-sl1c3d-l4bs-performance.conf`).
- **Target path:** the new canonical path (e.g. `host/arch/sysctl/99-sl1c3d-l4bs-performance.conf` or `dot_config/systemd/user/quickshell.service`).
- **Current owner:** `chezmoi`, `host`, `generated`, `Arch packages`, or `Nix`.
- **Target owner:** same domain, but with new owner if moving (e.g. `host` instead of `system-config`, or `Nix` instead of `Arch packages`).
- **Responsible phase:** which Masterclass phase drives the migration.
- **Rollback commands:** concrete commands or steps to revert the move.
- **Status:** `planned`, `in-progress`, or `completed`.

---

### 2. Example (Template Only)

These are **examples only**, not executed migrations. They demonstrate how Phase 7, 8, and 10 will use this ledger:

```text
Artifact ID: host-sysctl-performance
Current path: dot_config/SL1C3D-L4BS/system-config/sysctl.d/99-sl1c3d-l4bs-performance.conf
Target path: host/arch/sysctl/99-sl1c3d-l4bs-performance.conf
Current owner: chezmoi (system-config)
Target owner: host
Responsible phase: Phase 7 (Architecture scaffolding)
Rollback commands:
  - Remove host/arch/sysctl/99-sl1c3d-l4bs-performance.conf from the host.
  - Re-run the original system-config installer: executable_install-sysctl.sh.
Status: planned
```

```text
Artifact ID: daemon-quickshell
Current path: Hyprland autostart (exec-once quickshell)
Target path: dot_config/systemd/user/quickshell.service
Current owner: Hyprland autostart.conf (chezmoi-managed)
Target owner: systemd user (unit described in chezmoi)
Responsible phase: Phase 6 (systemd session, TTY-only)
Rollback commands:
  - Disable quickshell.service for the user.
  - Restore the Phase 0 exec-once quickshell line in autostart.conf.
Status: completed
```

(Phase 6 completed: quickshell, swaync, clipboard-history, swww, wallpaper-restore, hypridle, ags, theme-propagation are now user units; autostart.conf reduced to minimal glue.)

```text
Artifact ID: pkg-neovim
Current path: Arch package (pacman/AUR)
Target path: Nix flake (e.g. nix/home/…)
Current owner: Arch packages
Target owner: Nix packages
Responsible phase: Phase 8 (Nix Mode A)
Rollback commands:
  - Remove neovim from the Nix profile or flake output.
  - Reinstall neovim via pacman or AUR helper per package-ownership.md.
Status: planned
```

---

### 3. Phase Responsibilities and Rollback

- **Phase 7:** owns host and system-config moves into `host/arch/`.  
  - Must create ledger entries for each moved artifact.  
  - Rollback uses the `Rollback commands` field to restore the original host configuration.

- **Phase 8:** owns package moves between Arch and Nix.  
  - Must create ledger entries for each package migration in parallel with updates to `docs/architecture/package-ownership.md`.  
  - Rollback is explicitly documented per package class.

- **Phase 6 and Phase 10:** own session and physical refactors impacting systemd user units or directory layout.  
  - Each such change must appear in this ledger with before/after and rollback commands, in addition to the proofs required in Phase 10.

At the end of Phase 1, this file defines the contract and structure for the ledger but records no completed migrations, satisfying the no-placeholder rule by being purely structural and explicit about future responsibilities.

