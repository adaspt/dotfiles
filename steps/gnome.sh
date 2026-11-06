# GNOME extensions and settings. Settings live in config/gnome.ini.

install_packages gnome
flatpak install -y --noninteractive --system flathub be.alexandervanhee.gradia

# ---------- Personal extensions ----------
# Cloned to personal projects, symlinked into the extensions dir
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

# ---------- Settings ----------
echo "Applying GNOME settings from config/gnome.ini"
dconf load / < "$DOTFILES_DIR/config/gnome.ini"

# Battery charging - Preserve Battery Health (stored by UPower, not dconf)
for battery in $(upower -e | grep battery_); do
  upower -i "$battery" | grep -q 'charge-threshold-supported: *yes' || continue
  gdbus call --system --dest org.freedesktop.UPower --object-path "$battery" \
    --method org.freedesktop.UPower.Device.EnableChargeThreshold true >/dev/null
done

# Wi-Fi and Bluetooth off - last, so the downloads above can still use Wi-Fi
nmcli radio wifi off
rfkill block bluetooth

needs_restart "log out and back in, so GNOME Shell loads the new extensions"
