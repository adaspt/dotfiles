#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

cp "$DOTFILES_DIR/config/.zshrc" "$HOME/"
cp "$DOTFILES_DIR/config/.p10k.zsh" "$HOME/"

sudo pacman -S --needed --noconfirm zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search
yay -S --noconfirm zsh-theme-powerlevel10k

[[ "$SHELL" != */zsh ]] && chsh -s "$(which zsh)"
