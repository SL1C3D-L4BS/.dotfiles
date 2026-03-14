## Components — Quickshell, AGS, and Related UI

This document incorporates:

- Phase 0 inventory (Quickshell and AGS components): `docs/inventory/phase0-inventory.md`
- Phase 0 decisions (AGS quarantine, theme and motion model): `docs/inventory/phase0-decisions.md`
- Phase 0 contradictions (Quickshell vs AGS roles): `docs/inventory/phase0-contradictions.md`

---

### 1. Quickshell Components (Strategic UI)

Quickshell is the **strategic UI framework** for the bar and related surfaces. Key components include:

- **Bar:** workspace indicators, system status, AI panel toggle, notification indicators.  
- **SystemInfo:** CPU/RAM and system stats.  
- **AIPanel:** OpenClaw-based AI sidebar.

All Quickshell components:

- Must source color, spacing, radius, and motion from the canonical design tokens (once Phase 4 introduces them).  
- Are migration-capable only within Quickshell itself (refactors and reorganizations), not toward AGS.

**Responsible phases:** Phase 4 (tokens) and Phase 9 (UI convergence).  
**Rollback:** revert Quickshell component changes via VCS to the Phase 0 versions if convergence work introduces regressions.

---

### 2. AGS Components (Quarantine Model)

AGS currently provides a quicksettings panel and other auxiliary UI surfaces. Under the Masterclass plan:

- AGS is a **temporary compatibility layer**.  
- Every AGS component must be assigned:
  - A decision: **keep**, **migrate to Quickshell**, or **delete**.  
  - An owner: the person or role responsible.  
  - A milestone or date for the decision to be enacted.

Phase 9 enumeration — every AGS component has decision, owner, and milestone/date:

| Component | Artifact(s) | Decision | Owner | Milestone/date | Target or justification |
|-----------|-------------|----------|-------|----------------|-------------------------|
| QuickSettings panel | `widget/QuickSettings.tsx`, QS panel in `style.scss` | **keep** | operator | 2026-Q2 review | Quickshell has no equivalent yet; retain until parity or alternative. |
| AGS app shell | `app.ts`, `style.scss`, `sl1c3d-tokens.scss` | **keep** | operator | 2026-Q2 review | Required for QuickSettings; lockstep with QuickSettings. |
| AGS theme tokens | `sl1c3d-tokens.scss` | **keep** | operator | 2026-Q2 review | Consumer output; canonical source is repo theme.tokens.toml. |

No new AGS features unless Quickshell cannot cover them. Before milestone: re-evaluate migrate / delete / keep; extend milestone if keeping.

**Responsible phase:** Phase 9 (UI convergence).  
**Rollback:** classify a component as “keep” with justification if migration or deletion proves harmful; this restores its status as a first-class AGS feature with explicit documentation.

---

### 3. Error States and Feedback

For both Quickshell and AGS:

- User-triggered actions (toggles, buttons, commands) must provide visible success or failure feedback.  
- Failure modes (e.g. unable to reach AI service, missing dependency) should:
  - Degrade gracefully (e.g. display a message in the panel).  
  - Not violate the do-not-break list from `docs/inventory/phase0-do-not-break.md`.

**Responsible phases:** Phase 3 (doctor feedback for operator surfaces) and Phase 9 (UI refinement).  
**Rollback:** revert component-level changes if new error handling introduces regressions; the baseline behavior from Phase 0 remains available in VCS.

---

### 4. Token and Motion Convergence

- All components (Quickshell and AGS) must:
  - Use the canonical design tokens for colors, spacing, and radius (`docs/design-system/tokens.md`); no duplicated UI constants outside the token system.  
  - Use standardized motion durations (120/180/260 ms) and curve names (easeOutCubic, easeOutExpo, easeInCubic) from `docs/design-system/motion.md`.  
- QML (Bar.qml, BrandTheme.qml) and SCSS (sl1c3d-tokens.scss) consume from repo theme or generated outputs only.

