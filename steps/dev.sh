# Development tools (optional: ./install dev).

# ---------- Repos ----------
# Claude Desktop: unofficial repackaging of Anthropic's .deb, no official Fedora package yet
[ -f /etc/yum.repos.d/claude-desktop-unofficial.repo ] ||
  sudo curl -fsSLo /etc/yum.repos.d/claude-desktop-unofficial.repo https://pkg.claude-desktop-debian.dev/rpm/claude-desktop-unofficial.repo

# Azure CLI: Microsoft's RHEL 10 repo, Fedora's package lags behind
rpm -q packages-microsoft-prod &> /dev/null || {
  sudo rpm --import https://packages.microsoft.com/keys/microsoft-2025.asc
  sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm
}

install_packages dev

# ---------- Claude Desktop ----------
# Native Wayland instead of XWayland: its X11 window left open at logout makes GNOME Shell hang on shutdown
link config/environment.d/claude.conf "$HOME/.config/environment.d/claude.conf"

# ---------- ChatGPT ----------
rpm -q chatgpt &> /dev/null ||
  sudo dnf install -y https://persistent.oaistatic.com/codex-app-prod/linux/rpm/latest/chatgpt.x86_64.rpm

# ---------- Claude Code (native install, auto-updates) ----------
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash

# ---------- Codex CLI (native install) ----------
[ -x "$HOME/.local/bin/codex" ] || curl -fsSL https://chatgpt.com/codex/install.sh | sh

# ---------- nvm (PROFILE=/dev/null: .zshrc already loads it) ----------
[ -d "$HOME/.nvm" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash

needs_restart "log out and back in for CLAUDE_USE_WAYLAND"
