# OneDrive client syncing the folders in config/onedrive/sync_list. The ssh and vpn steps after it read Backup/.

CONFIG_DIR="$HOME/.config/onedrive"

sudo dnf install -y onedrive
onedrive --version

# Copied, not symlinked: changing config or sync_list makes the client refuse to sync until --resync,
# so a git pull shouldn't change them under a running client. Existing files are kept.
mkdir -p "$CONFIG_DIR"
for f in config sync_list; do
  [ -f "$CONFIG_DIR/$f" ] || cp "$DOTFILES_DIR/config/onedrive/$f" "$CONFIG_DIR/$f"
done

# ---------- Authenticate, first sync ----------
if ! systemctl --user is-enabled --quiet onedrive; then
  if [ ! -f "$CONFIG_DIR/refresh_token" ]; then
    # Exits non-zero after auth because no --sync/--monitor was given
    onedrive || true
    [ -f "$CONFIG_DIR/refresh_token" ] || die "OneDrive authentication failed"
  fi

  # Only Backup/ now: the ssh and vpn steps need it, and the full first sync can take long.
  # The client demands --resync on the first sync with a sync_list (no saved state yet)
  onedrive --sync --single-directory Backup --resync --resync-auth --verbose

  # The service syncs the rest in the background.
  # Linger (enabled later by the base step) keeps it syncing when not logged in
  systemctl --user enable --now onedrive
fi

systemctl --user status onedrive --no-pager || true
echo "OneDrive is set up. Follow logs with: journalctl --user -u onedrive -f"
