#!/usr/bin/env bash
set -euo pipefail

# ---------- Steam ----------
read -p "Do you want to install Steam? (y/N) " INSTALL_STEAM
if [[ "$INSTALL_STEAM" == "y" || "$INSTALL_STEAM" == "Y" ]]; then
  # RPM Fusion's Steam repo comes with fedora-workstation-repositories, disabled unless third-party repos were enabled at install
  sudo dnf config-manager setopt rpmfusion-nonfree-steam.enabled=1
  sudo dnf install -y steam
fi

# ---------- GeForce NOW ----------
read -p "Do you want to install GeForce NOW? (y/N) " INSTALL_GEFORCE_NOW
if [[ "$INSTALL_GEFORCE_NOW" == "y" || "$INSTALL_GEFORCE_NOW" == "Y" ]]; then
  DOWNLOADS_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"
  INSTALLER="$DOWNLOADS_DIR/GeForceNOWSetup.bin"

  mkdir -p "$DOWNLOADS_DIR"
  curl -fSL -o "$INSTALLER" https://international.download.nvidia.com/GFNLinux/GeForceNOWSetup.bin
  chmod +x "$INSTALLER"

  "$INSTALLER"
fi
