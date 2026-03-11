#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Build chezmoi from source (SL1C3D-L4BS). Requires Go 1.24+.
# Run: paru -S go && bash build-chezmoi-from-source.sh
# Binary: ~/.local/bin/chezmoi (or $HOME/go/bin if using go install path)
# ─────────────────────────────────────────────────────────────────────────────

set -e
BUILD_DIR="${BUILD_DIR:-${TMPDIR:-/tmp}/chezmoi-build}"
INSTALL_PREFIX="${INSTALL_PREFIX:-$HOME/.local}"
mkdir -p "$BUILD_DIR" "$INSTALL_PREFIX/bin"
cd "$BUILD_DIR"

if ! command -v go &>/dev/null; then
	echo "Go is required. Install with: paru -S go"
	exit 1
fi

if [[ ! -d chezmoi ]]; then
	git clone --depth 1 https://github.com/twpayne/chezmoi.git
fi
cd chezmoi

# Option A: make install (PREFIX) — installs to $INSTALL_PREFIX/bin
make install PREFIX="$INSTALL_PREFIX"
echo "Installed chezmoi to $INSTALL_PREFIX/bin"
"$INSTALL_PREFIX/bin/chezmoi" version
