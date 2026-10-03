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

# 3. Desktop preferences
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.interface cursor-size 32
gsettings set org.gnome.desktop.search-providers disable-external true
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state "true"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'lt')]"
gsettings set org.gnome.nautilus.icon-view default-zoom-level 'small-plus'
gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
gsettings set org.gnome.shell favorite-apps "['chrome-ompifgpmddkgmclendfeacglnodjjndh-Default.desktop', 'com.mitchellh.ghostty.desktop', 'google-chrome.desktop', 'com.microsoft.VSCode.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Calculator.desktop']"

# 4. Create shortcut "Screenshot with Gradia interactive" (Shift+Super+s)
GRADIA_SHORTCUT_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$GRADIA_SHORTCUT_PATH']"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH name "Screenshot with Gradia interactive"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH command "flatpak run be.alexandervanhee.gradia --screenshot=INTERACTIVE"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$GRADIA_SHORTCUT_PATH binding "<Shift><Super>s"

# 5. Switch windows of application
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Alt>F6']"
gsettings set org.gnome.desktop.wm.keybindings cycle-group "['<Super>Above_Tab']"

# 6. Ubuntu Dock - bottom, auto-hide, not full width
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false


# ---------- GNOME Extensions ----------
echo "Installing GNOME extensions..."

sudo apt-get install -y gnome-browser-connector
flatpak install -y --noninteractive --system flathub be.alexandervanhee.gradia

# 1. From extensions.gnome.org (Happy Appy Hotkey, Caffeine) - confirm each install dialog
for uuid in happy-appy-hotkey@jqno.nl caffeine@patapon.info; do
  gnome-extensions list | grep -qxF "$uuid" && continue
  gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Extensions.InstallRemoteExtension "$uuid"
done

# 2. Window Width
WINDOW_WIDTH_DIR="$HOME/.local/share/gnome-shell/extensions/window-width@adaspt"
if [ ! -d "$WINDOW_WIDTH_DIR/.git" ]; then
  git clone git@github.com:adaspt/gnome-shell-extension-window-width.git "$WINDOW_WIDTH_DIR"
else
  git -C "$WINDOW_WIDTH_DIR" pull --ff-only
fi

# 3. Focus Ring
FOCUS_RING_DIR="$HOME/.local/share/gnome-shell/extensions/focus-ring@adaspt"
if [ ! -d "$FOCUS_RING_DIR/.git" ]; then
  git clone git@github.com:adaspt/gnome-shell-extension-focus-ring.git "$FOCUS_RING_DIR"
else
  git -C "$FOCUS_RING_DIR" pull --ff-only
fi
