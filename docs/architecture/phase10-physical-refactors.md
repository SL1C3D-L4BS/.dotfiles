# Phase 10 — Physical Refactors (Proof-Based)

Per the Masterclass plan, physical refactors (file or directory moves) are **only if justified** and require **proof**, not opinion.

---

### 1. Eligibility

A physical refactor may proceed only if it shows at least one:

- Measurable maintenance reduction  
- Reduced ownership ambiguity  
- Reduced runtime complexity  

**Acceptable candidates:** host-owned artifacts from system-config → `host/arch/`; standalone scripts → `tools/`; consolidate legacy theme fragments under one generation path.  
**Not acceptable:** moving `dot_config/` into `chezmoi/dot_config/` (already decided against).

---

### 2. Required Proof (Per Move)

For each move, document:

- **Before tree** — directory/file listing of affected paths before the move.  
- **After tree** — same after the move.  
- **Ownership diff** — what changed owner (e.g. system-config → host/arch).  
- **Rollback command sequence** — concrete commands to revert (e.g. git revert, or re-copy from system-config).  
- **Validation output** — `sl1c3d validate` (or validate-configs) after the move.  
- **Benchmark comparison** — if startup or runtime paths changed, run `sl1c3d benchmark` and record before/after.

Update migration-ledger with the entry; update bootstrap and docs if layout or sourceDir changes.

---

### 3. Implementation Status

**No physical refactors were executed in this Masterclass implementation.** Phase 7 added `host/arch/`, `tools/`, and `nix/` **additively** with migration notes pointing to current live artifacts; no files were moved from system-config into host/arch or from dot_config into tools. Theme pipeline remains under `dot_config/SL1C3D-L4BS/theme/` with canonical source in repo.

Future moves (e.g. migrating a system-config installer into `host/arch/packages/`) must follow §1–§2 and the migration-ledger contract.
