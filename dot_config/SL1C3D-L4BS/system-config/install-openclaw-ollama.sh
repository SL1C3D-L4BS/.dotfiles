#!/usr/bin/env bash
# SL1C3D-L4BS — OpenClaw + Ollama stack (Node 22+, Ollama, OpenClaw gateway)
# Run: ./install-openclaw-ollama.sh
# Optional: pass --pull-models to pull recommended Ollama models after install.

set -e
PULL_MODELS=false
for arg in "$@"; do
  [ "$arg" = "--pull-models" ] && PULL_MODELS=true
done

echo "[SL1C3D-L4BS] Installing Node.js 22+ and npm..."
sudo pacman -S --needed --noconfirm nodejs npm
node -v | grep -qE 'v2[2-9]|v3' || { echo "Node 22+ required. Install manually if needed."; exit 1; }

echo "[SL1C3D-L4BS] Installing Ollama..."
if command -v ollama &>/dev/null; then
  echo "  ollama already installed: $(ollama --version 2>/dev/null || true)"
else
  if command -v paru &>/dev/null; then
    paru -S --noconfirm ollama
  elif command -v yay &>/dev/null; then
    yay -S --noconfirm ollama
  else
    echo "  Install ollama from https://ollama.com or: paru -S ollama"
    exit 1
  fi
fi

echo "[SL1C3D-L4BS] Installing OpenClaw (npm global)..."
npm install -g openclaw@latest

echo "[SL1C3D-L4BS] OpenClaw + Ollama stack installed."
echo "  Next: mkdir -p ~/.openclaw/workspace"
echo "  Copy workspace templates from ~/.config/SL1C3D-L4BS/openclaw-workspace-templates/ to ~/.openclaw/workspace/"
echo "  Start Ollama: ollama serve (or systemctl --user start ollama)"
echo "  Pull models: ollama pull qwen2.5-coder:7b && ollama pull deepseek-r1:7b"
echo "  Start gateway: openclaw gateway start"
echo "  Open UI: Super+Shift+A or http://127.0.0.1:18789/"

if [ "$PULL_MODELS" = true ]; then
  echo "[SL1C3D-L4BS] Pulling recommended Ollama models..."
  ollama serve &>/dev/null &
  sleep 2
  ollama pull qwen2.5-coder:7b || true
  ollama pull deepseek-r1:7b || true
  echo "  Done. Run 'ollama list' to see models."
fi
