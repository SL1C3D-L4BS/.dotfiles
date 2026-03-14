## Benchmarks — SL1C3D-L4BS

Baselines and thresholds are defined in `docs/architecture/performance-budget.md`. This document summarizes how to run benchmarks.

- **Script:** `ci/startup-bench.sh` (run from repo root: `~/.local/share/chezmoi`).
- **Entry point:** `sl1c3d benchmark` — runs the script and enforces hard-fail thresholds (+20% vs Phase 0 baselines). Exits non-zero when any surface exceeds its threshold.
- **Surfaces:** shell startup, Neovim startuptime, validate-configs duration. Label: **pre–systemd migration** (Phase 5).

Reproducibility rules (environment, warm/cold, CI-safe vs manual) are in performance-budget.md.
