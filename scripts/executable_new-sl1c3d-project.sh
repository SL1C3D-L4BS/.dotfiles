#!/usr/bin/env bash
# SL1C3D-L4BS — New project generator (from scaffolds)

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  new-sl1c3d-project.sh <scaffold> <target_dir>

Scaffolds:
  web-next
  api-fastapi
  infra-terraform
  obs-otel
EOF
}

if [ $# -ne 2 ]; then
  usage
  exit 2
fi

scaffold="$1"
target="$2"

src="$HOME/.config/SL1C3D-L4BS/scaffolds/$scaffold"
if [ ! -d "$src" ]; then
  echo "Unknown scaffold: $scaffold"
  echo "Available:"
  ls -1 "$HOME/.config/SL1C3D-L4BS/scaffolds" | sed 's/^/  - /'
  exit 2
fi

if [ -e "$target" ] && [ "$(ls -A "$target" 2>/dev/null | wc -l | tr -d ' ')" -gt 0 ]; then
  echo "Target directory not empty: $target"
  exit 2
fi

mkdir -p "$target"
cp -a "$src/." "$target/"

echo "Created project:"
echo "  scaffold: $scaffold"
echo "  target:   $target"
