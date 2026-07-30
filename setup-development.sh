#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

sudo pacman -S --needed --noconfirm nvm azure-cli
yay -S --noconfirm dotnet-runtime-10.0 dotnet-sdk-10.0 aspnet-runtime-10.0 aspnet-targeting-pack-10.0

yay -S --noconfirm claude-code claude-desktop
