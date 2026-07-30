#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

sudo pacman -Syu --needed --noconfirm base-devel git

if ! command -v yay &> /dev/null; then
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  pushd "$tmpdir/yay" >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpdir"
fi

mkdir -p "$DOTFILES_DIR"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone https://github.com/adaspt/dotfiles.git "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" remote set-url origin git@github.com:adaspt/dotfiles.git
fi

sudo pacman -S --needed --noconfirm pacman-contrib age eza fzf ghostty htop openssh networkmanager tmux zoxide zsh ttf-jetbrains-mono-nerd yazi 7zip
yay -S --noconfirm google-chrome visual-studio-code-bin

# ---------- Configs ----------
cp "$DOTFILES_DIR/config/.gitconfig" "$HOME/"
cp "$DOTFILES_DIR/config/.tmux.conf" "$HOME/"


# ---------- Fonts ----------
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts"/* "$HOME/.local/share/fonts"
fc-cache -fv

# --------- Maintenance ----------
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now paccache.timer
