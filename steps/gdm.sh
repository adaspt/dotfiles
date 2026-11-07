# Login screen (GDM greeter): same monitor layout as the desktop, and no suspend while it waits.

# Monitor layout: a path unit copies ~/.config/monitors.xml to GDM every time Settings > Displays saves it,
# so arranging the monitors after the final restart (with the final GPU driver) is enough
enable_monitor_sync() {
  sudo systemctl daemon-reload
  sudo systemctl enable --now "gdm-monitors@$USER.path"
  # Copy the current layout right away; skipped quietly while there is none
  sudo systemctl start "gdm-monitors@$USER.service"
}
put etc/systemd/system/gdm-monitors@.path etc/systemd/system/gdm-monitors@.service -- enable_monitor_sync

if ask "Disable suspend on the login screen?"; then
  # Fedora's gdm package already ships the dconf profile with system-db:gdm
  put etc/dconf/db/gdm.d/00-disable-suspend -- sudo dconf update
fi
