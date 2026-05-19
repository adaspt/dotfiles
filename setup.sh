#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="$HOME/OneDrive"
ONEDRIVE_REMOTE="onedrive-personal"
FILES=(
  "Backup/agersi-vpn.conf.age"
  "Backup/ssh.tar.gz.age"
)

sudo dnf install -y rclone age zsh

if ! rclone listremotes | grep -qx "${ONEDRIVE_REMOTE}:"; then
  rclone config create "$ONEDRIVE_REMOTE" onedrive config_driveid="24ED83B92E9CD012" config_drivetype="personal"
fi

mkdir -p "$DEST_DIR"

for file in "${FILES[@]}"; do
  echo "Downloading: $file"
  mkdir -p "$DEST_DIR/$(dirname "$file")"
  rclone copyto "${ONEDRIVE_REMOTE}:$file" "$DEST_DIR/$file" --progress
done

# ---------- SSH ----------
mkdir -p "$HOME/.ssh"
if [ -f "$DEST_DIR/Backup/ssh.tar.gz.age" ]; then
  echo "Setting up SSH keys"
  age --decrypt "$DEST_DIR/Backup/ssh.tar.gz.age" > "$DEST_DIR/Backup/ssh.tar.gz"
  tar -xzf "$DEST_DIR/Backup/ssh.tar.gz" -C "$HOME/.ssh"
  rm "$DEST_DIR/Backup/ssh.tar.gz"
fi

chmod 700 "$HOME/.ssh"
chmod 600 ~/.ssh/id_*
chmod 644 ~/.ssh/*.pub
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/authorized_keys
chmod 644 ~/.ssh/known_hosts

# ---------- VPN ----------
if ! nmcli connection show agersi-vpn &> /dev/null; then
  echo "Setting up VPN connection"
  age --decrypt "$DEST_DIR/Backup/agersi-vpn.conf.age" > "$DEST_DIR/Backup/agersi-vpn.conf"
  nmcli connection import type wireguard file "$DEST_DIR/Backup/agersi-vpn.conf"
  nmcli connection modify agersi-vpn connection.autoconnect no
  rm "$DEST_DIR/Backup/agersi-vpn.conf"
fi

# ---------- Resources ----------
echo "Setting up resources"
DOTFILES_DIR="$HOME/Projects/personal/dotfiles"
mkdir -p "$DOTFILES_DIR"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone git@github.com:adaspt/dotfiles.git "$DOTFILES_DIR" # || true
else
  git -C "$DOTFILES_DIR" pull
fi

# ---------- Shell configuration ----------
echo "Setting up shell and configuration"
chsh -s "$(which zsh)"
cp -r "$DOTFILES_DIR/config"/* "$HOME/"
mkdir -p "$HOME/.zsh"
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$HOME/.zsh/fast-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$HOME/.zsh/zsh-autosuggestions"

# ---------- Fonts ----------
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts/*" "$HOME/.local/share/fonts"
fc-cache -fv

# ---------- Yazi ----------
if ! command -v yazi &> /dev/null; then
  echo "Setting up Yazi"
  sudo dnf copr enable lihaohong/yazi
  sudo dnf install yazi
fi

# ---------- Gradia ----------
if ! command -v gradia &> /dev/null; then
  echo "Setting up Gradia"
  flatpak install -y flathub be.alexandervanhee.gradia
fi

BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/gradia-screenshot/"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH name "Gradia Screenshot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$BASE_PATH binding "<Super><Shift>s"
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$BASE_PATH']"

# ---------- Gnome extensions ----------
echo "Setting up Gnome extensions"
gnome-extensions install-extension 307 # dash-to-dock
