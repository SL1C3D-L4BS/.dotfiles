#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS — Secret audit (strict local-only secrets)
# Scans the chezmoi source for obvious secret markers.
# NOTE: This is a heuristic gate, not a guarantee.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT="${1:-$HOME/.local/share/chezmoi}"

if [ ! -d "$ROOT" ]; then
  echo "secret-audit: root not found: $ROOT"
  exit 2
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "secret-audit: ripgrep (rg) missing"
  exit 2
fi

# Patterns intentionally broad; allowlist via .secret-audit-allowlist if needed.
PATTERN='(gateway\.auth\.token|OPENAI_API_KEY|ANTHROPIC_API_KEY|GITHUB_TOKEN|GITHUB_PERSONAL_ACCESS_TOKEN|BRAVE_API_KEY|api[_-]?key|Authorization:\s*Bearer|BEGIN (OPENSSH|RSA|EC|PGP) PRIVATE KEY|ssh-ed25519|xox[baprs]-[0-9A-Za-z-]{10,}|AKIA[0-9A-Z]{16})'

ALLOWLIST_FILE="$ROOT/.secret-audit-allowlist"

echo "=== Secret audit (chezmoi source) ==="
echo "  root: $ROOT"

args=(--hidden --no-ignore-vcs --glob '!.git/**' --glob '!**/node_modules/**' --glob '!.cache/**' --glob '!**/*.log' --glob '!**/terminals/**')

if [ -f "$ALLOWLIST_FILE" ]; then
  # Allowlist contains literal substrings/regex fragments, one per line.
  echo "  allowlist: $ALLOWLIST_FILE"
fi

matches="$(rg "${args[@]}" -n -S -e "$PATTERN" "$ROOT" || true)"

if [ -n "$matches" ] && [ -f "$ALLOWLIST_FILE" ]; then
  filtered="$matches"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    filtered="$(printf '%s\n' "$filtered" | rg -v -e "$line" || true)"
  done < "$ALLOWLIST_FILE"
  matches="$filtered"
fi

if [ -n "$matches" ]; then
  echo "secret-audit: FAIL — possible secrets found:"
  printf '%s\n' "$matches"
  exit 1
fi

echo "secret-audit: OK — no obvious secrets found"
