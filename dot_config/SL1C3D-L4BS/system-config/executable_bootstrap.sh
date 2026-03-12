#!/usr/bin/env bash
# SL1C3D-L4BS — Bootstrap installer (edition-aware, commercial-grade defaults)
#
# Goals:
# - Deterministic edition installs from manifests
# - Safe logging + minimal rollback hooks (backup directory)
# - Idempotent package installs (pacman --needed)
#
# Strict local-only secrets: never writes or reads secrets.

set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ROOT="$CFG_DIR/SL1C3D-L4BS"
STATE_DIR="$ROOT/state/bootstrap"
SYSTEM_CONFIG_DIR="$ROOT/system-config"

usage() {
  cat <<'EOF'
Usage:
  bootstrap.sh [--edition <name>] [--dry-run]

Notes:
  - Edition manifests live at: ~/.config/SL1C3D-L4BS/editions/<edition>/manifest.json
  - Requires: sudo, pacman. For AUR: paru or yay (optional).
EOF
}

EDITION=""
DRY_RUN=false

while [ $# -gt 0 ]; do
  case "$1" in
    --edition)
      EDITION="${2:-}"; shift 2;;
    --dry-run)
      DRY_RUN=true; shift 1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1"; usage; exit 2;;
  esac
done

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1"; exit 2; }; }

need_cmd sudo
need_cmd pacman

if [ -z "$EDITION" ]; then
  if [ -x "$ROOT/bin/sl1c3d-edition" ]; then
    EDITION="$("$ROOT/bin/sl1c3d-edition" get || true)"
  fi
fi
[ -z "$EDITION" ] && EDITION="base"

MANIFEST="$ROOT/editions/$EDITION/manifest.json"
if [ ! -f "$MANIFEST" ]; then
  echo "Manifest not found for edition '$EDITION': $MANIFEST"
  echo "Hint: set edition first: ~/.config/SL1C3D-L4BS/bin/sl1c3d-edition set <edition>"
  exit 2
fi

ts="$(date +%Y%m%d-%H%M%S)"
run_dir="$STATE_DIR/$ts-$EDITION"
mkdir -p "$run_dir"
cp -a "$MANIFEST" "$run_dir/manifest.json"

# Record the edition as the active system edition (consumed by Quickshell hub)
mkdir -p "$ROOT/state"
cat >"$ROOT/state/edition.json" <<EOF
{
  "edition": "$(printf '%s' "$EDITION" | sed 's/\"/\\"/g')"
}
EOF

echo "[SL1C3D-L4BS] Bootstrap"
echo "  edition: $EDITION"
echo "  manifest: $MANIFEST"
echo "  state: $run_dir"

read_json_array() {
  local expr="$1"
  local file="$2"

  if command -v jq >/dev/null 2>&1; then
    jq -r "$expr[]? // empty" "$file"
    return 0
  fi

  python3 - "$expr" "$file" <<'PY'
import json, sys
expr, path = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
keys = expr.strip(".").split(".")
cur = data
for k in keys:
    cur = (cur or {}).get(k, None) if isinstance(cur, dict) else None
arr = cur if isinstance(cur, list) else []
for item in arr:
    if item is None:
        continue
    print(str(item))
PY
}

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '[dry-run] %q ' "$@"
    printf '\n'
    return 0
  fi
  "$@"
}

install_pacman() {
  mapfile -t pkgs < <(read_json_array '.packages.pacman' "$MANIFEST" | sed '/^$/d')
  if [ ${#pkgs[@]} -eq 0 ]; then
    echo "  pacman: none"
    return 0
  fi
  echo "  pacman: ${#pkgs[@]} packages"
  run sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur() {
  mapfile -t pkgs < <(read_json_array '.packages.aur' "$MANIFEST" | sed '/^$/d')
  if [ ${#pkgs[@]} -eq 0 ]; then
    echo "  aur: none"
    return 0
  fi

  local helper=""
  if command -v paru >/dev/null 2>&1; then helper="paru"; fi
  if [ -z "$helper" ] && command -v yay >/dev/null 2>&1; then helper="yay"; fi
  if [ -z "$helper" ]; then
    echo "  aur: SKIP (need paru or yay)"
    return 0
  fi
  echo "  aur: ${#pkgs[@]} packages via $helper"
  run "$helper" -S --needed --noconfirm "${pkgs[@]}"
}

enable_user_services() {
  mapfile -t units < <(read_json_array '.services.systemd_user_enable' "$MANIFEST" | sed '/^$/d')
  if [ ${#units[@]} -eq 0 ]; then
    echo "  systemd --user: none"
    return 0
  fi
  echo "  systemd --user enable: ${#units[@]} unit(s)"
  for u in "${units[@]}"; do
    run systemctl --user enable --now "$u" || true
  done
}

echo "[SL1C3D-L4BS] Installing packages..."
install_pacman
install_aur

echo "[SL1C3D-L4BS] Enabling services..."
enable_user_services

echo "[SL1C3D-L4BS] Optional modules (manual):"
echo "  - elite CLI: $SYSTEM_CONFIG_DIR/install-elite-stack.sh"
echo "  - dev stack: $SYSTEM_CONFIG_DIR/install-dev-stack.sh"
echo "  - sysctl:    $SYSTEM_CONFIG_DIR/install-sysctl.sh"
echo "  - pacman:    $SYSTEM_CONFIG_DIR/install-pacman-conf.sh"

echo "[SL1C3D-L4BS] Done."
