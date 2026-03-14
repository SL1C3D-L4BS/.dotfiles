#!/usr/bin/env bash
# SL1C3D-L4BS — Startup and config benchmarks (Phase 5)
# Runs: shell startup, Neovim startuptime, validate-configs duration.
# Output: one line per surface with label and seconds (or ms for nvim).

set -euo pipefail

ROOT="${1:-$PWD}"
cd "$ROOT"
HOME="${HOME:-$(getent passwd "$(whoami)" | cut -d: -f6)}"

run_shell_startup() {
  local t
  t=$( (time -p zsh -i -c 'exit' 2>/dev/null) 2>&1 | awk '/^real/ { print $2 }' || echo "0")
  echo "shell_startup	$t"
}

run_nvim_startuptime() {
  local log="${TMPDIR:-/tmp}/nvim-startup-bench-$$.log"
  nvim --headless --startuptime "$log" +qall 2>/dev/null || true
  local ms="0"
  if [ -f "$log" ]; then
    ms=$(awk '/NVIM STARTED/ { gsub(/^[0-9.]+\s+/, ""); print int($1*1000) }' "$log" | tail -1)
  fi
  echo "nvim_startup_ms	$ms"
}

run_validate_configs() {
  local script="$HOME/scripts/validate-configs.sh"
  local t="0"
  if [ -x "$script" ]; then
    t=$( (time -p "$script" >/dev/null 2>&1) 2>&1 | awk '/^real/ { print $2 }' || echo "0")
  fi
  echo "validate_configs	$t"
}

run_shell_startup
run_nvim_startuptime
run_validate_configs
