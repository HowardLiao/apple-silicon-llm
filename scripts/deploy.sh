#!/usr/bin/env bash
# ==============================================================================
# Apple Silicon Local LLM Zero-Homebrew Standalone Deployment Script
# Author: Howard Liao Ph.D.
# Hardware Target: Mac mini / MacBook Pro (Apple Silicon Unified Memory 24GB+)
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo "  Apple Silicon Local LLM Deployment (Ollama Standalone)"
echo "  Author: Howard Liao Ph.D."
echo "=========================================================="

ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
  echo "Error: This script is optimized for Apple Silicon (arm64). Detected: $ARCH"
  exit 1
fi

TOTAL_RAM_GB=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
echo "Detected RAM: ${TOTAL_RAM_GB} GB Unified Memory"

# 1. Check or Install Ollama.app
if [ ! -d "/Applications/Ollama.app" ]; then
  echo "[1/4] Downloading official Ollama Standalone for macOS..."
  TMP_DIR=$(mktemp -d /tmp/ollama-install.XXXXXX)
  curl -L -o "$TMP_DIR/Ollama-darwin.zip" https://ollama.com/download/Ollama-darwin.zip
  echo "Extracting Ollama.app to /Applications/..."
  unzip -q "$TMP_DIR/Ollama-darwin.zip" -d "$TMP_DIR"
  cp -R "$TMP_DIR/Ollama.app" /Applications/
  rm -rf "$TMP_DIR"
else
  echo "[1/4] Ollama.app already present in /Applications."
fi

# 2. Register CLI Symlink in ~/.local/bin
echo "[2/4] Registering CLI symlink in ~/.local/bin/ollama..."
mkdir -p "$HOME/.local/bin"
ln -sf /Applications/Ollama.app/Contents/Resources/ollama "$HOME/.local/bin/ollama"

# Ensure PATH includes ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# 3. Start Ollama Service
echo "[3/4] Ensuring Ollama background service is running..."
if ! curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
  open -a /Applications/Ollama.app
  for i in {1..15}; do
    if curl -s http://127.0.0.1:11434/api/version >/dev/null 2>&1; then
      echo "Ollama API daemon ready on port 11434."
      break
    fi
    sleep 1
  done
else
  echo "Ollama API daemon already active."
fi

# 4. Pull Primary Models
echo "[4/4] Pulling recommended dual-tier models for 24GB Unified Memory..."
echo "--> Pulling qwen2.5-coder:14b (Primary Reasoning & Coding Tier)..."
"$HOME/.local/bin/ollama" pull qwen2.5-coder:14b

echo "--> Pulling qwen2.5-coder:7b (Fast Autocomplete Tier)..."
"$HOME/.local/bin/ollama" pull qwen2.5-coder:7b

echo "=========================================================="
echo "Deployment Complete!"
echo "Current Models Available:"
"$HOME/.local/bin/ollama" list
echo "=========================================================="
