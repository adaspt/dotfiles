#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

read -p "Open Chrome, download SSH keys and VPN profile, and press Enter to continue: "

if [ -f "$HOME/Downloads/ssh.tar.gz.age" ]; then
  echo "Setting up SSH keys"
  age --decrypt "$HOME/Downloads/ssh.tar.gz.age" > "$HOME/Downloads/ssh.tar.gz"
  tar -xzf "$HOME/Downloads/ssh.tar.gz" -C "$HOME/.ssh"
  rm -f "$HOME/Downloads/ssh.tar.gz" "$HOME/Downloads/ssh.tar.gz.age"
fi

find "$HOME/.ssh" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
[ -f "$HOME/.ssh/authorized_keys" ] && chmod 600 "$HOME/.ssh/authorized_keys"
[ -f "$HOME/.ssh/known_hosts" ] && chmod 644 "$HOME/.ssh/known_hosts"

systemctl is-enabled --quiet sshd.service || sudo systemctl enable --now sshd.service


# ---------- VPN ----------
if [ -f "$HOME/Downloads/agersi-vpn.conf.age" ] && ! nmcli connection show agersi-vpn &> /dev/null; then
  echo "Setting up VPN connection"
  age --decrypt "$HOME/Downloads/agersi-vpn.conf.age" > "$HOME/Downloads/agersi-vpn.conf"
  nmcli connection import type wireguard file "$HOME/Downloads/agersi-vpn.conf"
  nmcli connection modify agersi-vpn connection.autoconnect no
  nmcli connection down agersi-vpn
  rm -f "$HOME/Downloads/agersi-vpn.conf" "$HOME/Downloads/agersi-vpn.conf.age"
fi
