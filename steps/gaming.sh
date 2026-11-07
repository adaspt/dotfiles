# Steam and GeForce NOW (optional: ./install gaming).

if ask "Install Steam?"; then
  # RPM Fusion's Steam repo comes with fedora-workstation-repositories, disabled unless third-party repos were enabled at install
  sudo dnf config-manager setopt rpmfusion-nonfree-steam.enabled=1
  sudo dnf install -y steam
fi

if ask "Install GeForce NOW?"; then
  # The installer writes GeForceNOWSetup.log to its working directory, so run it in a temp dir
  GFN_DIR="$(mktemp -d -t geforcenow.XXXXXX)"
  curl -fSL -o "$GFN_DIR/GeForceNOWSetup.bin" https://international.download.nvidia.com/GFNLinux/GeForceNOWSetup.bin
  chmod +x "$GFN_DIR/GeForceNOWSetup.bin"
  (cd "$GFN_DIR" && ./GeForceNOWSetup.bin) || die "GeForce NOW install failed, see $GFN_DIR/GeForceNOWSetup.log"
  rm -rf "$GFN_DIR"
fi
