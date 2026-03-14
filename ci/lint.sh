#!/usr/bin/env bash
# SL1C3D-L4BS — CI lint layer (headless-only)
# Phase 2: static checks only (scripts + dot_config), no environment/session checks.

set -euo pipefail

ROOT="${1:-$PWD}"

cd "$ROOT"

status=0

run_or_fail() {
  local name="$1"; shift
  echo "==> $name"
  if "$@"; then
    echo "    OK: $name"
  else
    echo "    FAIL: $name"
    status=1
  fi
}

if command -v shellcheck >/dev/null 2>&1; then
  run_or_fail "shellcheck (scripts)" \
    shellcheck scripts/executable_* ./*.sh 2>/dev/null || true
else
  echo "SKIP: shellcheck not installed"
fi

if command -v stylua >/dev/null 2>&1; then
  find dot_config -type f -name '*.lua' -print0 | xargs -0 -r stylua --check
else
  echo "SKIP: stylua not installed"
fi

if command -v luacheck >/dev/null 2>&1; then
  find dot_config -type f -name '*.lua' -print0 | xargs -0 -r luacheck
else
  echo "SKIP: luacheck not installed"
fi

exit "$status"

