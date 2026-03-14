## Performance Budget — Baselines and Targets

This budget is grounded in:

- Phase 0 benchmark baselines: `docs/inventory/phase0-benchmarks.md`
- Phase 0 inventory (validation surfaces): `docs/inventory/phase0-inventory.md`
- Phase 0 contradictions (need for enforceable gates): `docs/inventory/phase0-contradictions.md`

At Phase 1, it records baselines and intended budget structure; enforcement and automation belong to Phase 5.

---

### 1. Baseline Surfaces

From `phase0-benchmarks.md`:

| Surface                    | Command                                             | Baseline (single run) |
|---------------------------|------------------------------------------------------|------------------------|
| Interactive shell startup | `time zsh -i -c 'exit'`                             | ~0.079s total          |
| Neovim startup            | `nvim --headless --startuptime … +qall`            | ~45.658 ms             |
| Config validation         | `~/scripts/validate-configs.sh` (timed via `time`) | ~0.685s total          |

These values reflect the **Phase 0 stack** and must be considered when evaluating future regressions or improvements.

---

### 2. Budget Structure (Phase 5)

| Surface | Baseline (Phase 0) | Target | Acceptable regression (+10%) | Hard-fail (+20%) |
|---------|--------------------|--------|------------------------------|------------------|
| shell_startup | 0.079 s | ≤ 0.079 | ≤ 0.087 s | ≤ 0.095 s |
| nvim_startup_ms | 45.7 ms | ≤ 45.7 | ≤ 50.3 ms | ≤ 54.8 ms |
| validate_configs | 0.685 s | ≤ 0.685 | ≤ 0.754 s | ≤ 0.822 s |

`sl1c3d benchmark` runs `ci/startup-bench.sh`, parses output, and exits non-zero when any surface exceeds the hard-fail threshold. Label: pre–systemd migration.

---

### 3. Reproducibility Considerations

Phase 5 will add reproducibility rules; this section records the required dimensions:

- **Environment description:**  
  - Shell benchmark environment (login shell vs spawned shell).  
  - GPU and CPU load expectations during measurement.

- **Warm vs cold runs:**  
  - Number of initial “cold” runs to prime caches.  
  - Number of measured “warm” runs to compute stable averages.

- **Variance window:**  
  - Acceptable per-run deviation around the measured average before classification as a potential regression.

- **CI-safe vs manual benchmarks:**  
  - Which surfaces are safe and meaningful to run in CI (e.g. config validation).  
  - Which surfaces remain manual-only due to environment or hardware dependencies.

These dimensions are documented without speculative values; concrete numbers will be introduced in Phase 5 when the benchmark tooling is implemented.

---

### 4. Phase Responsibilities and Rollback

- **Phase 5:**  
  - Implements benchmark scripts and `sl1c3d benchmark`.  
  - Sets targets, regression windows, and hard-fail thresholds in reference to Phase 0 baselines.  
  - May adjust thresholds based on measured variance but must keep Phase 0 numbers visible as historical context.

- **Rollback:**  
  - If stricter thresholds prove impractical, Phase 5 may relax them while keeping this document consistent with actual benchmark behavior.  
  - Baseline values from Phase 0 remain as the reference and are not retroactively altered.

No placeholders are present; this document stops short of declaring numeric targets until benchmark tooling and multiple-run data are available.

