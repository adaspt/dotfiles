# WireGuard VPN connection agersi-vpn, from the secrets archive in OneDrive (unlock_secrets).
# Imported once and not connected automatically: turn it on in the GNOME quick settings.

if ! nmcli connection show agersi-vpn &> /dev/null; then
  unlock_secrets
  echo "Setting up VPN connection"
  # nmcli names the connection after the file
  nmcli connection import type wireguard file "$SECRETS_DIR/agersi-vpn.conf"
  nmcli connection modify agersi-vpn connection.autoconnect no
  nmcli connection down agersi-vpn || true
fi
