#!/usr/bin/env bash
# SL1C3D-L4BS — Install full 2026 dev stack (official + AUR)
# Run: ./install-dev-stack.sh

set -e

echo "[SL1C3D-L4BS] Installing official repo packages..."
sudo pacman -S --needed --noconfirm \
  npm python-pip python-pipx deno \
  docker docker-compose kubectl terraform \
  dotnet-sdk jdk17-openjdk php ruby zig uv \
  base-devel gcc clang cmake

echo "[SL1C3D-L4BS] Installing AUR packages (ollama)..."
paru -S --needed --noconfirm ollama-bin || true

echo "[SL1C3D-L4BS] Enabling docker socket (optional, for non-root docker)..."
sudo systemctl enable --now docker.socket 2>/dev/null || true

echo "[SL1C3D-L4BS] Dev stack installed. Add yourself to docker group to run without sudo: sudo usermod -aG docker $USER"
