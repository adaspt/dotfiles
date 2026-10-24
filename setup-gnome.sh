#!/usr/bin/env bash
set -euo pipefail

# GNOME-specific settings and extension installation.
# Run this only on a GNOME session or when GNOME is available.

# ---------- Packages (extensions first: their gsettings schemas are needed below) ----------
sudo dnf install -y gnome-browser-connector gnome-shell-extension-dash-to-dock gnome-shell-extension-caffeine gnome-shell-extension-appindicator

# ---------- GNOME Settings ----------
echo "Configuring GNOME desktop preferences..."

# 1. Turn off WiFi & bluetooth
nmcli radio wifi off
rfkill block bluetooth

# 2. Lock screen
gsettings set org.gnome.desktop.session idle-delay 480
gsettings set org.gnome.desktop.screensaver lock-delay 120
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

# Battery charging - Preserve Battery Health (stored by UPower, not gsettings)
for battery in $(upower -e | grep battery_); do
  upower -i "$battery" | grep -q 'charge-threshold-supported: *yes' || continue
  gdbus call --system --dest org.freedesktop.UPower --object-path "$battery" \
    --method org.freedesktop.UPower.Device.EnableChargeThreshold true >/dev/null
done

# 3. Desktop preferences
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.interface cursor-size 32
gsettings set org.gnome.desktop.search-providers disable-external true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state "true"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'lt')]"
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'
gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true
gsettings set org.gtk.gtk4.Settings.FileChooser sort-directories-first true
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.shell favorite-apps "['org.gnome.Calculator.desktop', 'com.mitchellh.ghostty.desktop', 'claude-desktop-unofficial.desktop', 'chatgpt.desktop', 'org.gnome.TextEditor.desktop', 'com.microsoft.VSCode.desktop', 'google-chrome.desktop', 'org.gnome.Nautilus.desktop', 'chrome-ompifgpmddkgmclendfeacglnodjjndh-Default.desktop']"

# 4. Create shortcut "Screenshot with Gradia interactive" (Shift+Super+s)
GRADIA_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$GRADIA_SHORTCUT_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH name "Screenshot with Gradia interactive"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH binding "<Shift><Super>s"

# 5. Close window
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"

# 6. Dash to Dock - bottom, auto-hide, not full width, fixed transparency
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock disable-overview-on-startup true


# ---------- GNOME Extensions ----------
echo "Installing GNOME extensions..."

flatpak install -y --noninteractive --system flathub be.alexandervanhee.gradia

# Personal extensions - cloned to personal projects, symlinked into the extensions dir
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXTENSIONS_DIR"
for NAME in launcher window-keys pr-monitor mail-monitor; do
  DIR="$HOME/Projects/personal/gnome-shell-extension-$NAME"
  if [ ! -d "$DIR/.git" ]; then
    mkdir -p "$(dirname "$DIR")"
    git clone "git@github.com:adaspt/gnome-shell-extension-$NAME.git" "$DIR"
  else
    git -C "$DIR" pull --ff-only
  fi
  # Compiled schemas are gitignored, so build them after clone/pull
  if [ -d "$DIR/schemas" ]; then
    glib-compile-schemas --strict "$DIR/schemas"
  fi
  ln -sfnT "$DIR" "$EXTENSIONS_DIR/$NAME@adaspt"
done
