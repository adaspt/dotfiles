#!/usr/bin/env bash

set -euo pipefail

# Ensure the script is run with sudo
if [ "${EUID:-}" -ne 0 ]; then
    echo "❌ Please run this script with sudo or as root:"
    echo "sudo ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TARGET_UDEV_RULE="/etc/udev/rules.d/00-remove-nvidia.rules"
TARGET_BLACKLIST="/etc/modprobe.d/blacklist-nvidia.conf"
SOURCE_UDEV_RULE="${SCRIPT_DIR}/00-remove-nvidia.rules"
SOURCE_BLACKLIST="${SCRIPT_DIR}/blacklist-nvidia.conf"

echo "🛠️  Starting NVIDIA isolation setup..."

echo "📦 Deploying udev rule..."
install -Dm644 "${SOURCE_UDEV_RULE}" "${TARGET_UDEV_RULE}"

echo "📦 Deploying modprobe blacklist..."
install -Dm644 "${SOURCE_BLACKLIST}" "${TARGET_BLACKLIST}"

echo "🔄 Reloading udev rules..."
udevadm control --reload-rules
udevadm trigger

echo "⚙️  Regenerating initramfs images..."
mkinitcpio -P

echo "✅ NVIDIA isolation setup completed."
echo "🔄 Please reboot your system to fully apply changes."
