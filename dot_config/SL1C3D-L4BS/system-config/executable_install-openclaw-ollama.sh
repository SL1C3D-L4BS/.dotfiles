#!/usr/bin/env bash
# SL1C3D-L4BS — OpenClaw + Ollama stack
# Official options: https://openclaw.ai/install-cli.sh (no root) or npm install -g openclaw
# Run: ./install-openclaw-ollama.sh
# Optional: --pull-models to pull Ollama models.

set -e
PULL_MODELS=false
for arg in "$@"; do
  [ "$arg" = "--pull-models" ] && PULL_MODELS=true
done

OPENCLAW_HOME="${OPENCLAW_PREFIX:-$HOME/.openclaw}"
[ -f "$OPENCLAW_HOME/openclaw.json" ] && cp -a "$OPENCLAW_HOME/openclaw.json" "$OPENCLAW_HOME/openclaw.json.bak.$$"

echo "[SL1C3D-L4BS] Installing OpenClaw..."

# Option 1: Official install-cli.sh (no root, installs Node + OpenClaw under ~/.openclaw)
if curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install-cli.sh 2>/dev/null | bash -s -- --prefix "$OPENCLAW_HOME" --no-onboard 2>/dev/null; then
  OPENCLAW_BIN="$OPENCLAW_HOME/bin"
  echo "[SL1C3D-L4BS] OpenClaw installed via install-cli.sh. Add to PATH: export PATH=\"$OPENCLAW_BIN:\$PATH\""
# Option 2: npm into ~/.openclaw (no root; requires Node 22+)
elif command -v node &>/dev/null && command -v npm &>/dev/null; then
  node -v | grep -qE 'v2[0-9]|v3' || { echo "Node 20+ required. Install: paru -S nodejs npm"; exit 1; }
  npm install -g --prefix "$OPENCLAW_HOME" openclaw@latest
  OPENCLAW_BIN="$OPENCLAW_HOME/bin"
  echo "[SL1C3D-L4BS] OpenClaw installed via npm. Add to PATH: export PATH=\"$OPENCLAW_BIN:\$PATH\""
else
  echo "[SL1C3D-L4BS] Install Node 22+ first, then re-run this script:"
  echo "  paru -S nodejs npm   # or: sudo pacman -S nodejs npm"
  echo "  Or run the official installer in your terminal (no root for OpenClaw):"
  echo "  curl -fsSL https://openclaw.ai/install-cli.sh | bash -s -- --prefix ~/.openclaw --no-onboard"
  exit 1
fi

[ -f "$OPENCLAW_HOME/openclaw.json.bak.$$" ] && mv "$OPENCLAW_HOME/openclaw.json.bak.$$" "$OPENCLAW_HOME/openclaw.json"

echo "[SL1C3D-L4BS] Ollama (requires sudo if not installed)..."
if command -v ollama &>/dev/null; then
  echo "  ollama already installed"
else
  if command -v paru &>/dev/null; then
    paru -S --noconfirm ollama
  elif command -v yay &>/dev/null; then
    yay -S --noconfirm ollama
  else
    echo "  Install: paru -S ollama  or  https://ollama.com"
  fi
fi

echo "[SL1C3D-L4BS] Next: mkdir -p ~/.openclaw/workspace && cp ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/*.md ~/.openclaw/workspace/"
echo "  Start gateway: openclaw gateway start   |   UI: Super+Shift+A or http://127.0.0.1:18789/"

if [ "$PULL_MODELS" = true ]; then
  (ollama serve &>/dev/null &); sleep 2
  ollama pull qwen2.5-coder:7b || true
  ollama pull deepseek-r1:7b || true
fi
