#!/usr/bin/env bash
set -euo pipefail

DOWNLOADS_DIR="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/Downloads")"
INSTALLER="$DOWNLOADS_DIR/GeForceNOWSetup.bin"

mkdir -p "$DOWNLOADS_DIR"
curl -fSL -o "$INSTALLER" https://international.download.nvidia.com/GFNLinux/GeForceNOWSetup.bin
chmod +x "$INSTALLER"

"$INSTALLER"
