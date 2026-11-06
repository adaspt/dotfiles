# Login screen (GDM greeter): same monitor layout as the desktop, and no suspend while it waits.

echo "Configure your monitors in Settings > Displays first, if you haven't yet."
if [ -f "$HOME/.config/monitors.xml" ] && ask "Copy the display config to the login screen?"; then
  sudo mkdir -p /var/lib/gdm/seat0/config
  sudo cp "$HOME/.config/monitors.xml" /var/lib/gdm/seat0/config/
fi

if ask "Disable suspend on the login screen?"; then
  # Fedora's gdm package already ships the dconf profile with system-db:gdm
  put etc/dconf/db/gdm.d/00-disable-suspend -- sudo dconf update
fi
