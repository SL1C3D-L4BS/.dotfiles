## Phase 0 — Baseline Benchmarks

Phase 0 captures **one-shot baseline measurements** for critical workflows. These are descriptive only; reproducibility rules and enforcement thresholds are introduced in Phase 5.

All measurements below were taken on the live SL1C3D-L4BS workstation at the time of Phase 0, under a typical Hyprland session.

---

### 1. Shell Startup (Interactive zsh)

- **Command:**

  ```bash
  time zsh -i -c 'exit'
  ```

- **Result (single run):**

  - `0.05s` user
  - `0.03s` system
  - **`0.079s` total**

- **Notes:**
  - Starship reported a `TERM=dumb` warning in this environment, but the measured wall time still reflects a realistic upper bound for non-interactive startup.

---

### 2. Neovim Startup

- **Command:**

  ```bash
  nvim --headless --startuptime /tmp/nvim-startup.log +qall
  tail -n 5 /tmp/nvim-startup.log
  ```

- **Result (excerpt):**

  ```text
  045.631  000.083: opening buffers
  045.651  000.020: BufEnter autocommands
  045.652  000.001: editing files in windows
  045.658  000.006: --- NVIM STARTED ---
  ```

- **Baseline:**

  - **~45.658 ms** to reach `--- NVIM STARTED ---` on this machine and config.

---

### 3. Config Validation Script (`validate-configs.sh`)

- **Command:**

  ```bash
  cd ~
  time ~/scripts/validate-configs.sh >/tmp/validate-configs.log 2>&1
  ```

- **Result (single run):**

  - `0.28s` user
  - `0.16s` system
  - **`0.685s` total**

- **Log summary:**

  - All Hyprland configs present and consistent (including autostart, binds, hyprlock, hypridle).
  - Yazi, Fuzzel, swaync, Ghostty, Quickshell, AGS, Zellij, and other key tools installed and passing their local config checks at the time of measurement.

---

### 4. Interpretation for Later Phases

- These numbers are **descriptive baselines** for:
  - Interactive shell startup.
  - Editor startup.
  - Config validation overhead.
- Phase 5 will:
  - Define **targets**, **acceptable regression windows**, and **hard-fail thresholds** relative to these baselines.
  - Introduce reproducible harnesses (cold vs warm runs, variance windows, CI-safe vs manual-only).
  - Wire `sl1c3d benchmark` and CI hooks to enforce performance budgets.

Until then, these Phase 0 measurements serve as the **reference point** for evaluating any future regression or improvement.

