#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"


# ---------- NVidia ----------
read -p "Disable discrete NVIDIA card? (y/N): " DISABLE_NVIDIA
if [[ "$DISABLE_NVIDIA" == "y" || "$DISABLE_NVIDIA" == "Y" ]]; then
  sudo bash "$DOTFILES_DIR/disable-nvidia/install.sh"
fi


# ---------- Login display config ----------
read -p "Do you want to copy existing display config to GDM Login screen? (y/N) " COPY_DISPLAY_CONFIG
if [[ "$COPY_DISPLAY_CONFIG" == "y" || "$COPY_DISPLAY_CONFIG" == "Y" ]]; then
  sudo mkdir -p /var/lib/gdm/seat0/config
  sudo cp "$HOME/.config/monitors.xml" /var/lib/gdm/seat0/config/
  sudo chown -R gdm:gdm /var/lib/gdm/seat0/config
fi


# ---------- Dependencies ----------
sudo pacman -Syu --needed --noconfirm base-devel git
sudo pacman -S --needed --noconfirm age eza fzf ghostty htop tmux zoxide zsh ttf-jetbrains-mono-nerd yazi

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


# ---------- Dotfiles ----------
echo "Setting up dotfiles"
mkdir -p "$(dirname "$DOTFILES_DIR")"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone git@github.com:adaspt/dotfiles.git "$DOTFILES_DIR"
else
  git -C "$DOTFILES_DIR" pull
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


# ---------- GNOME Settings ----------
echo "Configuring GNOME desktop preferences..."

# 1. Turn off WiFi & bluetooth
nmcli radio wifi off
rfkill block bluetooth

# 2. Lock screen
gsettings set org.gnome.desktop.session idle-delay 480
gsettings set org.gnome.desktop.screensaver lock-delay 120
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# 3. Desktop preferences
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.search-providers disable-external true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state "true"
gsettings set org.gnome.desktop.interface cursor-size 32
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'lt')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'
gsettings set org.gnome.shell favorite-apps "['org.gnome.Calculator.desktop', 'com.mitchellh.ghostty.desktop', 'google-chrome.desktop', 'code.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Nautilus.desktop']"
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

# 4. Create shortcut "Screenshot with Gradia interactive" (Shift+Super+s)
SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$SHORTCUT_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$SHORTCUT_PATH name "Screenshot with Gradia interactive"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$SHORTCUT_PATH command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$SHORTCUT_PATH binding "<Shift><Super>s"

# 5. Switch windows of application
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>F6']"
gsettings set org.gnome.desktop.wm.keybindings cycle-group "['<Super>Above_Tab']"

# 6. Weather
WEATHER_LOCATION="[<(uint32 2, <('Kaunas', 'EYKA', true, [(0.95818575934488692, 0.41748275707704363)], [(0.95818575934488692, 0.41713369122664473)])>)>]"
gsettings set org.gnome.Weather locations "$WEATHER_LOCATION"
gsettings set org.gnome.shell.weather locations "$WEATHER_LOCATION"
gsettings set org.gnome.shell.weather automatic-location false
gsettings set org.gnome.GWeather4 temperature-unit 'centigrade'


# ---------- GNOME Extensions ----------
echo "Installing GNOME extensions..."

# 1. Dash to Dock
gnome-browser-connector "gnome-extensions://dash-to-dock%40micxgx.gmail.com/?action=install"
export GSETTINGS_SCHEMA_DIR=$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/schemas/
read -p "Press Enter to configure Dash to Dock settings..."
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup "true"
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor "true"
gsettings set org.gnome.shell.extensions.dash-to-dock require-pressure-to-show "false"
gsettings set org.gnome.shell.extensions.dash-to-dock shortcut-timeout "5.0"
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode "'DYNAMIC'"

# 2. Clipboard indicator
gnome-browser-connector "gnome-extensions://clipboard-indicator%40tudmotu.com/?action=install"

# 3. Focus changer
gnome-browser-connector "gnome-extensions://focus-changer%40heartmire/?action=install"
export GSETTINGS_SCHEMA_DIR=$HOME/.local/share/gnome-shell/extensions/focus-changer@heartmire/schemas/
read -p "Press Enter to configure Focus changer settings..."
gsettings set org.gnome.shell.extensions.focus-changer focus-down "['<Control><Super>Down']"
gsettings set org.gnome.shell.extensions.focus-changer focus-left "['<Control><Super>Left']"
gsettings set org.gnome.shell.extensions.focus-changer focus-right "['<Control><Super>Right']"
gsettings set org.gnome.shell.extensions.focus-changer focus-up "['<Control><Super>Up']"

# 4. Window Width
WINDOW_WIDTH_DIR="$HOME/.local/share/gnome-shell/extensions/window-width@adaspt"
if [ ! -d "$WINDOW_WIDTH_DIR/.git" ]; then
  git clone git@github.com:adaspt/gnome-shell-extension-window-width.git "$WINDOW_WIDTH_DIR"
else
  git -C "$WINDOW_WIDTH_DIR" pull --ff-only
fi

# 5. Focus Ring
FOCUS_RING_DIR="$HOME/.local/share/gnome-shell/extensions/focus-ring@adaspt"
if [ ! -d "$FOCUS_RING_DIR/.git" ]; then
  git clone git@github.com:adaspt/gnome-shell-extension-focus-ring.git "$FOCUS_RING_DIR"
else
  git -C "$FOCUS_RING_DIR" pull --ff-only
fi
