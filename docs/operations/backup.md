## Backup — Data and Config Strategy

This strategy is informed by:

- Phase 0 inventory (`restic-backup.service`, scripts, and config layout): `docs/inventory/phase0-inventory.md`
- Phase 0 do-not-break list (no regressions to core workflows): `docs/inventory/phase0-do-not-break.md`

---

### 1. Backup Surfaces

Phase 0 identifies:

- **Configs:** `~/.config/**` as generated from `~/.local/share/chezmoi/dot_config/**`.  
- **Scripts:** `~/scripts/**`.  
- **Data:** assets (wallpapers, icons), tool state (e.g. Atuin history).

Backups should treat:

- `~/.local/share/chezmoi` as the canonical source-of-truth for config definitions.  
- `$HOME` (including `~/.config`) as runtime state that can be reconstructed from chezmoi plus data backups.

---

### 2. restic-Based Backups

From the inventory, `restic-backup.service` and its timer exist as user units defined under `dot_config/systemd/user/`.

At Phase 1:

- Use restic units as defined in the chezmoi source.  
- Confirm configuration (repository, include/exclude paths) prior to enabling the service or timer.  
- Avoid changing backup schedules or paths without updating both:
  - The restic unit configuration.  
  - This document.

Rollback is straightforward: disable the timer and restore prior restic configuration from version control.

---

### 3. Host vs Repo Responsibilities

- **Repo (`~/.local/share/chezmoi`):**  
  - Backed up as regular project data using Git hosting and external backups.  

- **Host data (`$HOME` and beyond):**  
  - Backed up via restic or equivalent tools with clear scope:
    - Include user data (documents, projects, media).  
    - Include any data directories whose loss would violate the do-not-break list (e.g. Atuin history, certain application state).

Future phases (7 and 10) that move host-level artifacts into `host/arch/` must update this document and the migration ledger to keep backup scope accurate.

