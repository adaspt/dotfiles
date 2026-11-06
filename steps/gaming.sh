# Steam and GeForce NOW (optional: ./install gaming).

if ask "Install Steam?"; then
  # RPM Fusion's Steam repo comes with fedora-workstation-repositories, disabled unless third-party repos were enabled at install
  sudo dnf config-manager setopt rpmfusion-nonfree-steam.enabled=1
  sudo dnf install -y steam
fi

if ask "Install GeForce NOW?"; then
  DOWNLOADS_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"
  INSTALLER="$DOWNLOADS_DIR/GeForceNOWSetup.bin"

  mkdir -p "$DOWNLOADS_DIR"
  curl -fSL -o "$INSTALLER" https://international.download.nvidia.com/GFNLinux/GeForceNOWSetup.bin
  chmod +x "$INSTALLER"
  "$INSTALLER"
fi
