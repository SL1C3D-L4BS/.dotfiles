#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SL1C3D-L4BS — Developer workstation 2026 (notes, streaming, API, DB, AI CLI)
# Run with:   bash ~/.config/SL1C3D-L4BS/system-config/install-developer-workstation.sh
#
# Do NOT paste the one-shot block into zsh — you may see:
#   zsh: command not found: #
#   zsh: unknown file attribute: i
# Those come from zsh mis-parsing pasted multi-line commands. Use this script.
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail
WARNED=()

run_pacman() {
  sudo pacman -S --noconfirm --needed "$@" 2>/dev/null && return 0
  WARNED+=("pacman: $*")
  return 1
}

run_paru() {
  command -v paru &>/dev/null || { echo "  [SKIP] paru not found"; return 1; }
  paru -S --noconfirm --needed "$@" 2>/dev/null && return 0
  WARNED+=("paru: $*")
  return 1
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   SL1C3D-L4BS Developer Workstation 2026 Install             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── Notes: Obsidian ─────────────────────────────────────────────────────────
echo "── Obsidian (notes) ───────────────────────────────────────────"
run_paru obsidian-bin || run_paru obsidian-appimage || echo "  [WARN] Obsidian: install manually from AUR or Flatpak"
echo ""

# ─── Streaming: OBS + Wayland + virtual cam ───────────────────────────────────
echo "── OBS Studio + streaming ──────────────────────────────────────"
KERNEL_HEADERS="linux-headers"
[[ "$(uname -r)" == *zen* ]] && KERNEL_HEADERS="linux-zen-headers"
run_pacman obs-studio qt6-wayland pavucontrol helvum ffmpeg $KERNEL_HEADERS || true
run_paru wlrobs || echo "  [WARN] wlrobs failed (Wayland capture fallback)"
run_paru obs-advanced-scene-switcher || echo "  [WARN] obs-advanced-scene-switcher failed"
run_paru v4l2loopback-dkms || echo "  [WARN] v4l2loopback-dkms failed (virtual cam; need matching kernel)"
echo ""

# ─── API & DB clients ────────────────────────────────────────────────────────
echo "── API & DB clients ───────────────────────────────────────────"
# bruno-bin = prebuilt (no nvm); bruno-electron needs nvm for Node 22+ build
run_paru bruno-bin || run_paru bruno-electron || run_paru bruno || echo "  [WARN] Bruno: paru -S bruno-bin (or npm i -g @usebruno/cli)"
run_pacman xh dbeaver || true
run_paru beekeeper-studio || echo "  [WARN] Beekeeper Studio: paru -S beekeeper-studio"
echo ""

# ─── Fullstack: fnm, bun, k9s, postgresql, redis, biome, ruff ─────────────────
echo "── Fullstack (fnm, bun, k9s, DBs, lint) ────────────────────────"
run_pacman fnm bun k9s biome ruff || true
run_pacman postgresql redis || true
echo ""

# ─── AI CLI ──────────────────────────────────────────────────────────────────
echo "── AI CLI (aichat) ─────────────────────────────────────────────"
run_pacman aichat || echo "  [WARN] aichat: sudo pacman -S aichat"
echo ""

# ─── Optional: Insomnia, Altair, Lens ────────────────────────────────────────
echo "── Optional (Insomnia, Altair) ─────────────────────────────────"
run_paru insomnia 2>/dev/null || true
run_paru altair 2>/dev/null || true
echo ""

# ─── Post-install hints ──────────────────────────────────────────────────────
echo "── Post-install ───────────────────────────────────────────────"
if pacman -Q postgresql &>/dev/null && [[ ! -d /var/lib/postgres/data ]]; then
  echo "  PostgreSQL: init DB with: sudo -u postgres initdb -D /var/lib/postgres/data"
  echo "  Then: sudo systemctl enable --now postgresql"
fi
echo "  Virtual cam (when needed): sudo modprobe v4l2loopback exclusive_caps=1 card_label='OBS Virtual Camera'"
echo "  OBS on Wayland: QT_QPA_PLATFORM=wayland obs"
echo ""

# ─── Summary ─────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Developer workstation install finished.                    ║"
if [[ ${#WARNED[@]} -gt 0 ]]; then
  echo "║  Warnings (optional or retry manually):                     ║"
  for w in "${WARNED[@]}"; do echo "║    - $w"; done
fi
echo "║  Run ~/scripts/validate-configs.sh to verify stack.         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
