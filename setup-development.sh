#!/usr/bin/env bash
set -euo pipefail

# ---------- Claude Desktop (unofficial repackaging of Anthropic's .deb, no official Fedora package yet) ----------
[ -f /etc/yum.repos.d/claude-desktop-unofficial.repo ] ||
  sudo curl -fsSLo /etc/yum.repos.d/claude-desktop-unofficial.repo https://pkg.claude-desktop-debian.dev/rpm/claude-desktop-unofficial.repo

# The rpm doesn't pull in the QEMU stack Cowork runs on
sudo dnf install -y azure-cli dotnet-sdk-10.0 claude-desktop-unofficial qemu-system-x86-core edk2-ovmf virtiofsd

# Claude Desktop Cowork needs /dev/kvm and /dev/vhost-vsock (takes effect after re-login)
id -nG "$USER" | grep -qw kvm || sudo usermod -aG kvm "$USER"

# Native Wayland instead of XWayland: its X11 window left open at logout makes GNOME Shell hang on shutdown (takes effect after re-login)
mkdir -p "$HOME/.config/environment.d"
echo 'CLAUDE_USE_WAYLAND=1' > "$HOME/.config/environment.d/claude.conf"

# ---------- ChatGPT ----------
rpm -q chatgpt &> /dev/null ||
  sudo dnf install -y https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm

# ---------- Claude Code (native install, auto-updates) ----------
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash

# ---------- nvm (PROFILE=/dev/null: .zshrc already loads it) ----------
[ -d "$HOME/.nvm" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash
