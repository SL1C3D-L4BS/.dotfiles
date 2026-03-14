#!/usr/bin/env bash
# SL1C3D-L4BS — CI docs lint (headless-only)
# Phase 2: Markdown lint for repo-only docs under docs/.

set -euo pipefail

ROOT="${1:-$PWD}"

DOCS_DIR="$ROOT/docs"

if [ ! -d "$DOCS_DIR" ]; then
  echo "ci/docs-lint: docs/ directory not found (nothing to lint)"
  exit 0
fi

if command -v markdownlint >/dev/null 2>&1; then
  markdownlint "$DOCS_DIR"
elif command -v markdownlint-cli2 >/dev/null 2>&1; then
  markdownlint-cli2 "$DOCS_DIR/**/*.md"
else
  echo "SKIP: markdownlint not installed"
fi

