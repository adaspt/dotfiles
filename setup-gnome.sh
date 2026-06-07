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
