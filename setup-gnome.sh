#!/usr/bin/env bash
set -euo pipefail

# GNOME-specific settings and extension installation.
# Run this only on a GNOME session or when GNOME is available.

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
gsettings set org.gnome.shell favorite-apps "['org.gnome.Calculator.desktop', 'com.mitchellh.ghostty.desktop', 'com.anthropic.Claude.desktop', 'chatgpt.desktop', 'org.gnome.TextEditor.desktop', 'com.microsoft.VSCode.desktop', 'google-chrome.desktop', 'org.gnome.Nautilus.desktop', 'chrome-ompifgpmddkgmclendfeacglnodjjndh-Default.desktop']"

# 4. Create shortcut "Screenshot with Gradia interactive" (Shift+Super+s)
GRADIA_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$GRADIA_SHORTCUT_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH name "Screenshot with Gradia interactive"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH binding "<Shift><Super>s"

# 5. Close window
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"

# 6. Ubuntu Dock - bottom, auto-hide, not full width, fixed transparency
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'

# 7. Desktop Icons - hide Home folder; Tiling Assistant - no popup after tiling a window
gsettings set org.gnome.shell.extensions.ding show-home false
gsettings set org.gnome.shell.extensions.tiling-assistant enable-tiling-popup false


# ---------- GNOME Extensions ----------
echo "Installing GNOME extensions..."

sudo apt-get install -y gnome-browser-connector
flatpak install -y --noninteractive --system flathub be.alexandervanhee.gradia

# 1. From extensions.gnome.org (Caffeine) - confirm the install dialog
for uuid in caffeine@patapon.info; do
  gnome-extensions list | grep -qxF "$uuid" && continue
  gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid"
done

# 2. Launcher - cloned to personal projects, symlinked into the extensions dir
LAUNCHER_DIR="$HOME/Projects/personal/gnome-shell-extension-launcher"
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
if [ ! -d "$LAUNCHER_DIR/.git" ]; then
  mkdir -p "$(dirname "$LAUNCHER_DIR")"
  git clone git@github.com:adaspt/gnome-shell-extension-launcher.git "$LAUNCHER_DIR"
else
  git -C "$LAUNCHER_DIR" pull --ff-only
fi
mkdir -p "$EXTENSIONS_DIR"
ln -sfnT "$LAUNCHER_DIR" "$EXTENSIONS_DIR/launcher@adaspt"
