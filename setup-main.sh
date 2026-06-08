#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"


# ---------- NVidia ----------
read -p "Disable discrete NVIDIA card? (y/N): " DISABLE_NVIDIA
if [[ "$DISABLE_NVIDIA" == "y" || "$DISABLE_NVIDIA" == "Y" ]]; then
  sudo bash "$DOTFILES_DIR/disable-nvidia/install.sh"
fi

# ---------- Wakeup events ----------
read -p "Disable wakeup events? (y/N): " DISABLE_WAKEUP
if [[ "$DISABLE_WAKEUP" == "y" || "$DISABLE_WAKEUP" == "Y" ]]; then
  sudo bash "$DOTFILES_DIR/disable-wakeup/install.sh"
fi


# ---------- Login display config ----------
read -p "Do you want to copy existing display config to GDM Login screen? (y/N) " COPY_DISPLAY_CONFIG
if [[ "$COPY_DISPLAY_CONFIG" == "y" || "$COPY_DISPLAY_CONFIG" == "Y" ]]; then
  sudo mkdir -p /var/lib/gdm/seat0/config
  sudo cp "$HOME/.config/monitors.xml" /var/lib/gdm/seat0/config/
  # sudo chown -R gdm:gdm /var/lib/gdm/seat0/config
fi


# ---------- Dependencies ----------
sudo pacman -Syu --needed --noconfirm base-devel git
sudo pacman -S --needed --noconfirm age eza fzf ghostty htop openssh networkmanager tmux zoxide zsh ttf-jetbrains-mono-nerd yazi

if ! command -v yay &> /dev/null; then
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpdir"
fi

yay -S --noconfirm google-chrome visual-studio-code-bin gradia


# ---------- SSH ----------
read -p "Open Chrome, download SSH keys and VPN profile, and press Enter to continue: "

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

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


# ---------- Shell configuration ----------
echo "Setting up shell"
[[ "$SHELL" != */zsh ]] && chsh -s "$(which zsh)"
cp -r "$DOTFILES_DIR/config/." "$HOME/"
mkdir -p "$HOME/.zsh"
if [ ! -d "$HOME/.zsh/fast-syntax-highlighting/.git" ]; then
  git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$HOME/.zsh/fast-syntax-highlighting"
else
  git -C "$HOME/.zsh/fast-syntax-highlighting" pull
fi
if [ ! -d "$HOME/.zsh/zsh-autosuggestions/.git" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions"
else
  git -C "$HOME/.zsh/zsh-autosuggestions" pull
fi
if [ ! -d "$HOME/.zsh/zsh-history-substring-search/.git" ]; then
  git clone https://github.com/zsh-users/zsh-history-substring-search.git "$HOME/.zsh/zsh-history-substring-search"
else
  git -C "$HOME/.zsh/zsh-history-substring-search" pull
fi


# ---------- Fonts ----------
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts"/* "$HOME/.local/share/fonts"
fc-cache -fv
