#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run this script with sudo or as root:"
    echo "sudo ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

echo "🛠️  Starting NVIDIA isolation setup..."

# 1. Deploy the udev rule with high priority (00-)
echo "📦 Copying udev rule..."
cp "${SCRIPT_DIR}/50-remove-nvidia.rules" /etc/udev/rules.d/00-remove-nvidia.rules
chmod 644 /etc/udev/rules.d/00-remove-nvidia.rules
chown root:root /etc/udev/rules.d/00-remove-nvidia.rules

# 2. Deploy the modprobe blacklist config
echo "📦 Copying modprobe blacklist..."
cp "${SCRIPT_DIR}/blacklist-nvidia.conf" /etc/modprobe.d/blacklist-nvidia.conf
chmod 644 /etc/modprobe.d/blacklist-nvidia.conf
chown root:root /etc/modprobe.d/blacklist-nvidia.conf

# 3. Reload udev rules to apply changes to the current session
echo "🔄 Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

# 4. Regenerate initcpio images for the early boot stage
echo "⚙️  Regenerating initcpio presets..."
mkinitcpio -P

echo "✅ Done! The malfunctioning NVIDIA GPU is permanently blocked."
echo "🔄 Please reboot your ThinkPad to fully apply changes."
