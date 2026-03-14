## Motion System — Durations and Curves

This description is aligned with:

- Phase 0 decisions (motion standardization: 120/180/260): `docs/inventory/phase0-decisions.md`
- Phase 4 canonical tokens: `theme.tokens.toml` section `[motion]` (fast_ms, normal_ms, slow_ms).

---

### 1. Motion Durations

Canonical durations are defined only in `theme.tokens.toml` and propagated by the theme generator:

- **Fast:** 120 ms  
- **Normal:** 180 ms  
- **Slow:** 260 ms

These durations apply to:

- Quickshell bar transitions (panel open/close, module animations).
- AGS quicksettings panel animations.
- Dialog and notification transitions where motion is present.

Phase 0 components may already approximate these durations; Phase 4 and Phase 9 will standardize them.

---

### 2. Motion Curves

Recommended easing curves (implemented as available in each toolkit):

- `easeOutCubic`
- `easeOutExpo`
- `easeInCubic`

Each animation in Quickshell, AGS, and other UI surfaces should:

- Use a named curve from this set (or a platform-equivalent).  
- Document the chosen curve in component-level docs where it materially affects UX.

---

### 3. Phase Responsibilities and Rollback

- **Phase 4:**  
  - Integrates motion durations into the canonical token source (e.g. `theme.tokens.toml`).  
  - Ensures the generated theme artifacts expose these durations for consumers such as QML and SCSS.

- **Phase 9:**  
  - Aligns Quickshell and AGS motion usage with the canonical durations and curves.  

**Rollback:**  
- If standardized motion results in regressions (e.g. accessibility concerns or perceived sluggishness), curves or durations can be adjusted in the canonical token source while keeping the structure defined here.

This document introduces no placeholder wording; it records concrete duration values and curve names without promising specific component changes before the relevant phases execute them.

