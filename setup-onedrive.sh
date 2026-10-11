#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/onedrive"

# ---------- Install ----------
sudo dnf install -y onedrive
onedrive --version

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

# ---------- Authenticate, first sync ----------
if ! systemctl --user is-enabled --quiet onedrive; then
  if [ ! -f "$CONFIG_DIR/refresh_token" ]; then
    # Exits non-zero after auth because no --sync/--monitor was given
    onedrive || true
    [ -f "$CONFIG_DIR/refresh_token" ] || { echo "OneDrive authentication failed"; exit 1; }
  fi

  # The client demands --resync on the first sync with a sync_list (no saved state yet)
  onedrive --sync --resync --resync-auth --verbose

  # Linger (enabled in setup.sh) keeps it syncing when not logged in
  systemctl --user enable --now onedrive
fi

systemctl --user status onedrive --no-pager || true
echo "OneDrive setup complete! Follow logs with: journalctl --user -u onedrive -f"
