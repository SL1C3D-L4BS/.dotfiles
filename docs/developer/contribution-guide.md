## Contribution Guide — SL1C3D-L4BS

This guide uses:

- Phase 0 inventories and decisions as architectural context: `docs/inventory/phase0-inventory.md`, `docs/inventory/phase0-decisions.md`
- Architecture docs in this directory, especially `system-overview.md` and `ownership-matrix.md`

It is repo-only and not deployed via chezmoi.

---

### 1. Workflow

1. Make changes under `~/.local/share/chezmoi`.  
2. Run:

   ```bash
   chezmoi diff
   ~/scripts/validate-configs.sh
   ```

3. Commit from the chezmoi source directory, following the existing commit style.  
4. Apply changes explicitly with `chezmoi apply` when you are ready to test them.

Avoid committing changes that:

- Rely on `chezmoi apply` being run automatically at login.  
- Introduce conflicting owners for the same artifact.

---

### 2. Respecting Phases

When contributing:

- Keep your work within the currently active phases.  
- If a change belongs to a later phase (e.g. Nix integration, theme generator), document it under `docs/architecture/` and defer implementation until that phase is active.

Every target or migration claim in code or docs should:

- Point to the responsible phase.  
- Reference the migration ledger where applicable.

---

### 3. Rollback Expectations

Every non-trivial change should have a clear rollback path:

- Revert changes in VCS.  
- Reapply previous configs via `chezmoi apply`.  
- Re-run `~/scripts/validate-configs.sh` to confirm that the system has returned to a known-good state.

Where a change affects host or package ownership, ensure that:

- The migration ledger is updated.  
- Package ownership rules are followed (Arch vs Nix).

