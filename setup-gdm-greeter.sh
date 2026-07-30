#!/usr/bin/env bash
set -euo pipefail

# ---------- Display config ----------
read -p "Do you want to copy existing display config to GDM Greeter screen? (y/N) " COPY_DISPLAY_CONFIG
if [[ "$COPY_DISPLAY_CONFIG" == "y" || "$COPY_DISPLAY_CONFIG" == "Y" ]]; then
  sudo mkdir -p /var/lib/gdm/seat0/config
  sudo cp "$HOME/.config/monitors.xml" /var/lib/gdm/seat0/config/
fi


# ---------- Disable greeter screen suspend ----------
read -p "Do you want to disable greeter screen suspend? (y/N) " DISABLE_SUSPEND
if [[ "$DISABLE_SUSPEND" == "y" || "$DISABLE_SUSPEND" == "Y" ]]; then
  sudo mkdir -p /etc/dconf/profile
  echo -e "user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults" | sudo tee /etc/dconf/profile/gdm
  sudo mkdir -p /etc/dconf/db/gdm.d
  echo -e "[org/gnome/settings-daemon/plugins/power]\nsleep-inactive-ac-type='nothing'\nsleep-inactive-ac-timeout=0" | sudo tee /etc/dconf/db/gdm.d/00-disable-suspend
  sudo dconf update
fi
