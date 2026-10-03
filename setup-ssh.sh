#!/usr/bin/env bash
set -euo pipefail

DOWNLOADS_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

read -p "Open Chrome, download SSH keys and VPN profile, and press Enter to continue: "

if [ -f "$DOWNLOADS_DIR/ssh.tar.gz.age" ]; then
  echo "Setting up SSH keys"
  age --decrypt "$DOWNLOADS_DIR/ssh.tar.gz.age" | tar -xz -C "$HOME/.ssh"
  rm -f "$DOWNLOADS_DIR/ssh.tar.gz.age"
fi

find "$HOME/.ssh" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
[ -f "$HOME/.ssh/authorized_keys" ] && chmod 600 "$HOME/.ssh/authorized_keys"
[ -f "$HOME/.ssh/known_hosts" ] && chmod 644 "$HOME/.ssh/known_hosts"


# ---------- VPN ----------
if [ -f "$DOWNLOADS_DIR/agersi-vpn.conf.age" ] && ! nmcli connection show agersi-vpn &> /dev/null; then
  echo "Setting up VPN connection"
  age --decrypt "$DOWNLOADS_DIR/agersi-vpn.conf.age" > "$DOWNLOADS_DIR/agersi-vpn.conf"
  nmcli connection import type wireguard file "$DOWNLOADS_DIR/agersi-vpn.conf"
  nmcli connection modify agersi-vpn connection.autoconnect no
  nmcli connection down agersi-vpn || true
  rm -f "$DOWNLOADS_DIR/agersi-vpn.conf" "$DOWNLOADS_DIR/agersi-vpn.conf.age"
fi
