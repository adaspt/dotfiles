#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

sudo pacman -Syu --needed --noconfirm base-devel git

mkdir -p "$DOTFILES_DIR"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone https://github.com/adaspt/dotfiles.git "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" remote set-url origin git@github.com:adaspt/dotfiles.git
fi

echo "Run the script: $DOTFILES_DIR/setup-main.sh to continue the setup process."
