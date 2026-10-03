#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/onedrive"

# ---------- Install (OpenSuSE Build Service repo, the Ubuntu package is outdated) ----------
if [ ! -f /etc/apt/sources.list.d/onedrive.list ]; then
  if compgen -G "/etc/apt/sources.list.d/yann1ck-*" >/dev/null; then
    sudo add-apt-repository -y --remove ppa:yann1ck/onedrive
  fi
  if dpkg -s onedrive &> /dev/null; then
    sudo apt-get remove -y onedrive
  fi

  OBS_REPO="https://download.opensuse.org/repositories/home:/npreining:/debian-ubuntu-onedrive/xUbuntu_$(lsb_release -rs)"
  curl -fsSL "$OBS_REPO/Release.key" | gpg --dearmor | sudo tee /usr/share/keyrings/obs-onedrive.gpg >/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/obs-onedrive.gpg] $OBS_REPO/ ./" | sudo tee /etc/apt/sources.list.d/onedrive.list >/dev/null
  sudo apt-get update
fi

sudo apt-get install -y --no-install-recommends --no-install-suggests onedrive
onedrive --version

# Packages enable a global user service; we enable our own below
sudo rm -f /etc/systemd/user/default.target.wants/onedrive.service

# ---------- Large trees hit inotify limits ----------
if [ ! -f /etc/sysctl.d/99-onedrive.conf ]; then
  echo 'fs.inotify.max_user_watches=524288' | sudo tee /etc/sysctl.d/99-onedrive.conf >/dev/null
  sudo sysctl --system >/dev/null
fi

# ---------- Config (changing config or sync_list later requires --resync) ----------
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config" ]; then
  cat > "$CONFIG_DIR/config" <<'EOF'
sync_dir = "~/OneDrive"
monitor_interval = "300"
EOF
fi

# Everything not listed here is excluded
if [ ! -f "$CONFIG_DIR/sync_list" ]; then
  cat > "$CONFIG_DIR/sync_list" <<'EOF'
/Apps/
/Temp/
EOF
fi

# ---------- Authenticate, verify, first sync ----------
if ! systemctl --user is-enabled --quiet onedrive; then
  if [ ! -f "$CONFIG_DIR/refresh_token" ]; then
    # Exits non-zero after auth because no --sync/--monitor was given
    onedrive || true
    [ -f "$CONFIG_DIR/refresh_token" ] || { echo "OneDrive authentication failed"; exit 1; }
  fi

  # The client demands --resync on the first sync with a sync_list (no saved state yet)
  onedrive --display-config
  onedrive --sync --resync --resync-auth --dry-run --verbose
  read -p "Review the dry run above and press Enter to start the first sync (Ctrl+C to abort): "
  onedrive --sync --resync --resync-auth --verbose

  # Linger (enabled in setup.sh) keeps it syncing when not logged in
  systemctl --user enable --now onedrive
fi

systemctl --user status onedrive --no-pager || true
echo "OneDrive setup complete! Follow logs with: journalctl --user -u onedrive -f"
