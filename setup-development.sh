#!/usr/bin/env bash
set -euo pipefail

# ---------- Azure CLI ----------
if [ ! -f /etc/apt/sources.list.d/azure-cli.sources ]; then
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
  echo "Types: deb
URIs: https://packages.microsoft.com/repos/azure-cli/
Suites: $(lsb_release -cs)
Components: main
Architectures: $(dpkg --print-architecture)
Signed-by: /etc/apt/keyrings/microsoft.gpg" | sudo tee /etc/apt/sources.list.d/azure-cli.sources >/dev/null
fi

# ---------- Claude Desktop ----------
if [ ! -f /etc/apt/sources.list.d/claude-desktop.list ]; then
  sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc https://downloads.claude.ai/claude-desktop/key.asc
  echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" | sudo tee /etc/apt/sources.list.d/claude-desktop.list >/dev/null
fi

sudo apt-get update
sudo apt-get install -y azure-cli dotnet-sdk-10.0 claude-desktop

# Claude Desktop Cowork needs /dev/kvm and /dev/vhost-vsock (takes effect after re-login)
id -nG "$USER" | grep -qw kvm || sudo usermod -aG kvm "$USER"

# ---------- ChatGPT (the .deb adds OpenAI's apt repo for updates) ----------
if ! dpkg -s chatgpt &> /dev/null; then
  tmp=$(mktemp --suffix=.deb)
  curl -fsSL -o "$tmp" https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb
  chmod 644 "$tmp"
  sudo apt-get install -y "$tmp"
  rm -f "$tmp"
fi

# ---------- Claude Code (native install, auto-updates) ----------
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash

# ---------- nvm (PROFILE=/dev/null: .zshrc already loads it) ----------
[ -d "$HOME/.nvm" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash
