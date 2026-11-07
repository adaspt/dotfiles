# SSH keys, from the secrets archive in OneDrive (unlock_secrets). Skipped once the keys are there,
# so running the step again doesn't ask for the passphrase.

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  unlock_secrets
  echo "Setting up SSH keys"
  cp -r "$SECRETS_DIR/ssh/." "$HOME/.ssh/"
fi

find "$HOME/.ssh" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[ ! -f "$HOME/.ssh/config" ] || chmod 600 "$HOME/.ssh/config"
[ ! -f "$HOME/.ssh/authorized_keys" ] || chmod 600 "$HOME/.ssh/authorized_keys"
[ ! -f "$HOME/.ssh/known_hosts" ] || chmod 644 "$HOME/.ssh/known_hosts"
