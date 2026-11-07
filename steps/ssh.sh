# SSH keys and the WireGuard VPN, from age-encrypted archives in OneDrive's Backup folder.
# Runs after the onedrive step, which syncs that folder. The archives stay there:
# deleting them would delete them from OneDrive too.

BACKUP_DIR="$HOME/OneDrive/Backup"

for f in ssh.tar.gz.age agersi-vpn.conf.age; do
  [ -f "$BACKUP_DIR/$f" ] || die "$BACKUP_DIR/$f not found. Is OneDrive synced? See: journalctl --user -u onedrive"
done

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Skipped once the keys are there, so running the step again doesn't ask for the passphrase
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "Setting up SSH keys"
  age --decrypt "$BACKUP_DIR/ssh.tar.gz.age" | tar -xz -C "$HOME/.ssh"
fi

find "$HOME/.ssh" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[ ! -f "$HOME/.ssh/config" ] || chmod 600 "$HOME/.ssh/config"
[ ! -f "$HOME/.ssh/authorized_keys" ] || chmod 600 "$HOME/.ssh/authorized_keys"
[ ! -f "$HOME/.ssh/known_hosts" ] || chmod 644 "$HOME/.ssh/known_hosts"

# ---------- VPN ----------
if ! nmcli connection show agersi-vpn &> /dev/null; then
  echo "Setting up VPN connection"
  # Decrypted into a private temp dir, never next to the archive, or OneDrive would upload it.
  # nmcli names the connection after the file, so the name matters
  VPN_DIR="$(mktemp -d)"
  age --decrypt "$BACKUP_DIR/agersi-vpn.conf.age" > "$VPN_DIR/agersi-vpn.conf"
  nmcli connection import type wireguard file "$VPN_DIR/agersi-vpn.conf"
  rm -rf "$VPN_DIR"
  nmcli connection modify agersi-vpn connection.autoconnect no
  nmcli connection down agersi-vpn || true
fi
