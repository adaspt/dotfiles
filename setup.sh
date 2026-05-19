#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="$HOME/OneDrive"
ONEDRIVE_REMOTE="onedrive-personal"
FILES=(
  "Backup/agersi-vpn.conf.age"
  "Backup/ssh.tar.gz.age"
)
TMP_FILES=()

cleanup() {
  if [ "${#TMP_FILES[@]}" -gt 0 ]; then
    rm -f "${TMP_FILES[@]}"
  fi
}
trap cleanup EXIT

sudo dnf install -y rclone age zsh

# ---------- Computer name ----------
read -p "Enter computer name (leave blank to skip): " COMPUTER_NAME
if [ -n "$COMPUTER_NAME" ]; then
  sudo hostnamectl set-hostname "$COMPUTER_NAME"
fi

# ---------- NVidia ----------
read -p "Disable discrete NVIDIA card? (y/n): " DISABLE_NVIDIA
if [[ "$DISABLE_NVIDIA" == "y" || "$DISABLE_NVIDIA" == "Y" ]]; then
  if ! command -v envycontrol &> /dev/null; then
    sudo dnf copr enable sunwire/envycontrol
    sudo dnf install python3-envycontrol
  fi
  sudo envycontrol -s integrated
fi

# ---------- OneDrive setup ----------
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
  ssh_archive="$(mktemp)"
  TMP_FILES+=("$ssh_archive")
  chmod 600 "$ssh_archive"
  age --decrypt "$DEST_DIR/Backup/ssh.tar.gz.age" > "$ssh_archive"
  tar -xzf "$ssh_archive" -C "$HOME/.ssh"
fi

chmod 700 "$HOME/.ssh"
find "$HOME/.ssh" -maxdepth 1 -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} +
find "$HOME/.ssh" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
[ -f "$HOME/.ssh/config" ] && chmod 600 "$HOME/.ssh/config"
[ -f "$HOME/.ssh/authorized_keys" ] && chmod 600 "$HOME/.ssh/authorized_keys"
[ -f "$HOME/.ssh/known_hosts" ] && chmod 644 "$HOME/.ssh/known_hosts"

# ---------- VPN ----------
if ! nmcli connection show agersi-vpn &> /dev/null; then
  echo "Setting up VPN connection"
  vpn_config="$(mktemp)"
  TMP_FILES+=("$vpn_config")
  chmod 600 "$vpn_config"
  age --decrypt "$DEST_DIR/Backup/agersi-vpn.conf.age" > "$vpn_config"
  nmcli connection import type wireguard file "$vpn_config"
  nmcli connection modify agersi-vpn connection.autoconnect no
fi

# ---------- Resources ----------
echo "Setting up resources"
DOTFILES_DIR="$HOME/Projects/personal/dotfiles"
mkdir -p "$(dirname "$DOTFILES_DIR")"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone git@github.com:adaspt/dotfiles.git "$DOTFILES_DIR"
else
  git -C "$DOTFILES_DIR" pull
fi

# ---------- Shell configuration ----------
echo "Setting up shell and configuration"
chsh -s "$(which zsh)"
cp -r "$DOTFILES_DIR/config"/* "$HOME/"
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

# ---------- Fonts ----------
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts"/* "$HOME/.local/share/fonts"
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
CURRENT_KEYBINDINGS="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)"
if [[ "$CURRENT_KEYBINDINGS" != *"'$BASE_PATH'"* && "$CURRENT_KEYBINDINGS" != *"\"$BASE_PATH\""* ]]; then
  if [[ "$CURRENT_KEYBINDINGS" == "@as []" || "$CURRENT_KEYBINDINGS" == "[]" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$BASE_PATH']"
  else
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "${CURRENT_KEYBINDINGS%]}, '$BASE_PATH']"
  fi
fi

# ---------- Gnome extensions ----------
# TODO: Investigate using gnome-browser-connector gnome-extensions://caffeine%40patapon.info/?action=install
# echo "Setting up Gnome extensions"
# if command -v gnome-extensions &> /dev/null && ! gnome-extensions list | grep -qx "dash-to-dock@micxgx.gmail.com"; then
#  sudo dnf install -y gnome-shell-extension-dash-to-dock || echo "Could not install dash-to-dock"
#  gnome-extensions enable dash-to-dock@micxgx.gmail.com || echo "Could not enable dash-to-dock"
# fi
