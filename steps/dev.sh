# Development tools.

# ---------- Repos ----------
# Azure CLI: Microsoft's RHEL 10 repo, Fedora's package lags behind
rpm -q packages-microsoft-prod &> /dev/null || {
  sudo rpm --import https://packages.microsoft.com/keys/microsoft-2025.asc
  sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm
}

install_packages dev

# ---------- Claude Code (native install, auto-updates) ----------
[ -x "$HOME/.local/bin/claude" ] || curl -fsSL https://claude.ai/install.sh | bash

# ---------- Codex CLI (native install) ----------
[ -x "$HOME/.local/bin/codex" ] || curl -fsSL https://chatgpt.com/codex/install.sh | sh

# ---------- T3 Code (AppImage) ----------
# It updates itself by replacing this file, so the name has no version in it.
# The release's file name does, so read it from latest-linux.yml, the manifest its updater uses.
# Downloaded to .part first, so an interrupted download isn't mistaken for an installed app on the next run
T3_APPIMAGE="$HOME/.local/bin/T3-Code.AppImage"
if [ ! -f "$T3_APPIMAGE" ]; then
  T3_FILE="$(curl -fsSL https://github.com/pingdotgg/t3code/releases/latest/download/latest-linux.yml | sed -n 's/^path: //p')"
  curl -fSL -o "$T3_APPIMAGE.part" "https://github.com/pingdotgg/t3code/releases/latest/download/$T3_FILE"
  chmod +x "$T3_APPIMAGE.part"
  mv "$T3_APPIMAGE.part" "$T3_APPIMAGE"
fi

# Menu entry. The icon is written by the app on its first start, along with a hidden entry for t3code:// links
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/t3code.desktop" << EOF
[Desktop Entry]
Type=Application
Name=T3 Code
Exec=$T3_APPIMAGE %U
Icon=$HOME/.local/share/icons/com.t3tools.T3Code.desktop.png
Terminal=false
StartupNotify=true
StartupWMClass=com.t3tools.T3Code
EOF

# ---------- nvm (PROFILE=/dev/null: .zshrc already loads it) ----------
[ -d "$HOME/.nvm" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash
