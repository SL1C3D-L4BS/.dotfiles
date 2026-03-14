#!/usr/bin/env bash
# SL1C3D-L4BS — Theme generator entry script (Phase 4)
# Single authoritative pipeline. Only invoked via: sl1c3d theme apply

set -euo pipefail

SOURCE_DIR="${SL1C3D_SOURCE_DIR:-${CHEZMOI_SOURCE_DIR:-$HOME/.local/share/chezmoi}}"
if [ -n "${1:-}" ]; then
  SOURCE_DIR="$1"
fi

GENERATOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$GENERATOR_DIR/generate.py"

if [ ! -f "$PYTHON_SCRIPT" ]; then
  echo "theme-generator: generate.py not found: $PYTHON_SCRIPT" >&2
  exit 1
fi

export SL1C3D_SOURCE_DIR="$SOURCE_DIR"
exec python3 "$PYTHON_SCRIPT" "$SOURCE_DIR"
