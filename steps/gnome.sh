# GNOME extensions and settings. Settings live in config/gnome.ini.

install_packages gnome
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
    git -C "$DIR" pull --ff-only
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
# Suspend settings, the same file the gdm step installs for the login screen
dconf load / < "$DOTFILES_DIR/files/etc/dconf/db/gdm.d/00-power-$(power_type)"

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

# Wi-Fi and Bluetooth off - last, so the downloads above can still use Wi-Fi
nmcli radio wifi off
rfkill block bluetooth

needs_restart "GNOME Shell loads the new extensions"
