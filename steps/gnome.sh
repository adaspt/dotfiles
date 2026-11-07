# GNOME extensions and settings, for the desktop session and the login screen (GDM greeter).
# Settings live in config/gnome.ini.

# Extensions from Fedora's repos, enabled by config/gnome.ini below
sudo dnf install -y gnome-browser-connector gnome-shell-extension-dash-to-dock \
  gnome-shell-extension-caffeine gnome-shell-extension-appindicator
flatpak install -y --noninteractive --system flathub be.alexandervanhee.gradia

# ---------- Personal extensions ----------
# Cloned to personal projects, symlinked into the extensions dir.
# Over HTTPS, so no SSH key is needed yet; .gitconfig sends pushes over SSH
EXTENSIONS_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXTENSIONS_DIR"
for NAME in launcher window-keys mail-monitor; do
  DIR="$HOME/Projects/personal/gnome-shell-extension-$NAME"
  if [ ! -d "$DIR/.git" ]; then
    mkdir -p "$(dirname "$DIR")"
    git clone "https://github.com/adaspt/gnome-shell-extension-$NAME.git" "$DIR"
  else
    # Local commits or changes make this fail; keep the clone as it is then
    git -C "$DIR" pull --ff-only || echo "Couldn't update $DIR, keeping it as it is."
  fi
  # Compiled schemas are gitignored, so build them after clone/pull
  if [ -d "$DIR/schemas" ]; then
    glib-compile-schemas --strict "$DIR/schemas"
  fi
  ln -sfnT "$DIR" "$EXTENSIONS_DIR/$NAME@adaspt"
done

# ---------- Settings ----------
echo "Applying GNOME settings from config/gnome.ini"
dconf load / < "$DOTFILES_DIR/config/gnome.ini"

# ---------- Suspend ----------
# When idle: a laptop after 15 minutes on battery and 1 hour plugged in, a desktop never.
# One file for both: installed for the login screen (Fedora's gdm package already ships the dconf
# profile with system-db:gdm), and loaded into this session
POWER_FILE="etc/dconf/db/gdm.d/00-power-$(power_type)"
put "$POWER_FILE" -- sudo dconf update
dconf load / < "$DOTFILES_DIR/config/system/$POWER_FILE"

# ---------- Login screen monitors ----------
# A path unit copies ~/.config/monitors.xml to GDM every time Settings > Displays saves it,
# so arranging the monitors after the final restart (with the final GPU driver) is enough
enable_monitor_sync() {
  sudo systemctl daemon-reload
  sudo systemctl enable --now "gdm-monitors@$USER.path"
  # Copy the current layout right away; skipped quietly while there is none
  sudo systemctl start "gdm-monitors@$USER.service"
}
put etc/systemd/system/gdm-monitors@.path etc/systemd/system/gdm-monitors@.service -- enable_monitor_sync

# ---------- Wallpaper ----------
# From OneDrive (synced by the onedrive step), copied to where Settings keeps wallpapers,
# so it stays even if the original is moved or deleted
WALLPAPER="winter-mountain-3840x2160-24311.jpg"
if [ -f "$HOME/OneDrive/Backup/$WALLPAPER" ]; then
  mkdir -p "$HOME/.local/share/backgrounds"
  cp "$HOME/OneDrive/Backup/$WALLPAPER" "$HOME/.local/share/backgrounds/$WALLPAPER"
  for key in picture-uri picture-uri-dark; do
    gsettings set org.gnome.desktop.background "$key" "file://$HOME/.local/share/backgrounds/$WALLPAPER"
  done
else
  echo "$WALLPAPER not found in ~/OneDrive/Backup, keeping the current wallpaper."
fi

# Battery charging - Preserve Battery Health (stored by UPower, not dconf)
for battery in $(upower -e | grep battery_); do
  upower -i "$battery" | grep -q 'charge-threshold-supported: *yes' || continue
  gdbus call --system --dest org.freedesktop.UPower --object-path "$battery" \
    --method org.freedesktop.UPower.Device.EnableChargeThreshold true >/dev/null
done

needs_restart "GNOME Shell loads the new extensions"
