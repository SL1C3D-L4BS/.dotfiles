## Cursor Rules — SL1C3D-L4BS

This file complements:

- Workspace-level rules (e.g. `AGENTS.md`, `.cursor/rules/sl1c3d-l4bs-stack.mdc`)
- Phase 0 inventories and decisions for architecture context: `docs/inventory/phase0-inventory.md`, `docs/inventory/phase0-decisions.md`

It is repo-only and not deployed via chezmoi.

---

### 1. General Principles

- Treat `~/.local/share/chezmoi` as the **single source of truth** for config definitions.  
- Avoid editing files under `$HOME` directly unless the change is intentionally local and not meant for version control.  
- Keep alignment with the Masterclass plan and Phase 0 decision artifacts when proposing structural changes.

---

### 2. Editing and Validation

- Prefer editing files under `~/.local/share/chezmoi` and then running:

  ```bash
  chezmoi apply
  ~/scripts/validate-configs.sh
  ```

- For Hyprland, Quickshell, swaync, Ghostty, and AGS:
  - Confirm changes still pass validation and do not violate the Phase 0 do-not-break list.

---

### 3. Phases and Scope

- Do not introduce Nix ownership of configs before Phase 8.  
- Do not move durable daemons into systemd units before Phase 6.  
- Do not introduce new theme token sources before Phase 4; instead, prepare for consolidation.

When adjusting architecture, always reference:

- `docs/architecture/system-overview.md`
- `docs/architecture/ownership-matrix.md`
- `docs/architecture/migration-ledger.md`

This keeps developer work in sync with the documented model.

