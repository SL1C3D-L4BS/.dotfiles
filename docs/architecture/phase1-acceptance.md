## Phase 1 — Acceptance Check

This document records the Phase 1 acceptance results and any remaining tensions. It references:

- Phase 0 inventories and decisions:  
  - `docs/inventory/phase0-inventory.md`  
  - `docs/inventory/phase0-decisions.md`  
  - `docs/inventory/phase0-benchmarks.md`  
  - `docs/inventory/phase0-do-not-break.md`  
  - `docs/inventory/phase0-contradictions.md`
- All Phase 1 docs created under `docs/architecture/`, `docs/design-system/`, `docs/operations/`, and `docs/developer/`.

---

### 1. Hard Acceptance Requirements

**Requirement 1 — Every Phase 1 document must cite a Phase 0 artifact.**

- Each new document added in Phase 1 includes an explicit “This document references …” section at the top, naming at least one of the Phase 0 inventory or decision files.

**Requirement 2 — No placeholder wording.**

- Phase 1 documents avoid terms such as “TBD” or “or equivalent”.  
- Forward-looking sections describe:
  - Which phase is responsible.  
  - What kind of work will occur.  
  - Without inventing fake specifics (e.g. exact paths or values that are not yet known).

**Requirement 3 — Every target or migration claim maps to a responsible phase.**

- Architecture targets (UWSM session, theme consolidation, Nix Mode A, AGS quarantine) are mapped to phases 3–10 in:
  - `docs/architecture/system-overview.md`  
  - `docs/architecture/ownership-matrix.md`  
  - `docs/architecture/package-ownership.md`

**Requirement 4 — Every migration-capable area has rollback language or an explicit no-rollback-needed note.**

- Session, theme, host/arch, package, and UI migrations all include rollback descriptions in the relevant docs:
  - `system-overview.md` (session model)  
  - `ownership-matrix.md` (artifact ownership)  
  - `migration-ledger.md` (per-artifact rollback commands)  
  - `package-ownership.md` (Arch↔Nix rollback rules)

**Requirement 5 — Docs remain repo-only and are not deployed via chezmoi.**

- The top-level `docs/` directory lives under `~/.local/share/chezmoi/docs/`.  
- `.chezmoiignore` now contains `docs/`, ensuring that these documents are not materialized into `$HOME` on `chezmoi apply`.

---

### 2. Contradictions Between Phase 0 Outputs and Written Architecture

Phase 1 documents **describe** the target architecture while Phase 0 describes current reality. The main contradictions (also listed in `phase0-contradictions.md`) are:

- **Session model:**  
  - Phase 0: Hyprland `exec-once` + sleeps; no UWSM installed.  
  - Architecture docs: describe UWSM-managed sessions and systemd user units anchored on `graphical-session.target`.  
  - Status: intentional gap; implementation deferred to Phase 6.

- **Theme ownership:**  
  - Phase 0: scattered theme sources.  
  - Architecture and design-system docs: describe a single canonical tokens file and runtime JSON.  
  - Status: intentional gap; implementation deferred to Phase 4.

- **Nix integration:**  
  - Phase 0: Arch-only packages, no `nix/` directory.  
  - Package ownership doc: defines class-based Nix policies.  
  - Status: intentional gap; implementation deferred to Phase 8.

- **AGS quarantine:**  
  - Phase 0: AGS is active alongside Quickshell without a decision matrix.  
  - Components doc: declares AGS as quarantined and requiring decisions.  
  - Status: intentional gap; implementation deferred to Phase 9.

These contradictions are explicitly acknowledged and tied to phases with rollback notes, rather than silently assumed away.

---

### 3. Target Claims Not Yet Writable Without Placeholders

Phase 1 deliberately avoids making claims where details cannot be specified without placeholders. Examples include:

- **Exact `host/arch/` directory contents:**  
  - Architecture docs mention `host/arch/` as the future single path of record but do not list concrete files or per-distro variants, because those depend on future migration work.  
  - Status: will be specified in Phase 7 with concrete entries in `migration-ledger.md`.

- **Exact contents of `theme.tokens.toml` or equivalent:**  
  - Design-system docs define categories and responsibilities but do not invent the full token schema yet.  
  - Status: will be specified in Phase 4 when the generator and token file structure are implemented.

- **Full AGS component table (keep/migrate/delete):**  
  - Components doc defines the requirement but does not enumerate every AGS component and decision.  
  - Status: will be specified in Phase 9 using an up-to-date component inventory.

By omitting such details now and documenting them here as intentionally deferred, Phase 1 avoids violating the no-placeholder rule while still constraining how future work must proceed.

---

### 4. Phase 1 Status

- Top-level `docs/` structure exists and is repo-only.  
- Architecture, design-system, operations, and developer documents have been created and tied to Phase 0 outputs.  
- Hard acceptance requirements are satisfied as described above.

No Phase 2 work has been initiated; CI scripts and workflows remain for later phases.

