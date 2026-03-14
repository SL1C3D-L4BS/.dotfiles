#!/usr/bin/env bash
# SL1C3D-L4BS — CI secret audit wrapper (headless)
# Phase 2: runs the existing audit-secrets script against the chezmoi source.

set -euo pipefail

ROOT="${1:-$PWD}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUDIT_SCRIPT="$SCRIPT_DIR/scripts/executable_audit-secrets.sh"

if [ ! -f "$AUDIT_SCRIPT" ]; then
  echo "ci/secret-audit: audit script not found: $AUDIT_SCRIPT"
  exit 1
fi

chmod +x "$AUDIT_SCRIPT"
"$AUDIT_SCRIPT" "$SCRIPT_DIR"

