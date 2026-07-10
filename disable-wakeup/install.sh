#!/usr/bin/env bash

set -euo pipefail

# Ensure the script is run with sudo
if [ "${EUID:-}" -ne 0 ]; then
    echo "❌ Please run this script with sudo or as root:"
    echo "sudo ./install.sh"
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
TARGET_FILE="/etc/tmpfiles.d/disable-wakeup.conf"
SOURCE_FILE="${SCRIPT_DIR}/disable-wakeup.conf"

echo "🛠️  Setting up wakeup event disablement..."
cp "$SOURCE_FILE" "$TARGET_FILE"
echo "✅ wakeup event disablement configured."
