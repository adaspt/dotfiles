#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

sudo apt-get update
sudo apt-get full-upgrade -y
sudo apt-get install -y git curl

install_deb() {
  local name="$1" url="$2" tmp
  if ! dpkg -s "$name" &> /dev/null; then
    tmp=$(mktemp --suffix=.deb)
    curl -fsSL -o "$tmp" "$url"
    chmod 644 "$tmp"
    sudo apt-get install -y "$tmp"
    rm -f "$tmp"
  fi
}

mkdir -p "$DOTFILES_DIR"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone -b ubuntu https://github.com/adaspt/dotfiles.git "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" remote set-url origin git@github.com:adaspt/dotfiles.git
fi

if [ ! -f /etc/apt/sources.list.d/yazi.list ]; then
  curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
  sudo apt-get update
fi

sudo apt-get install -y age eza fzf bat ghostty htop btop tmux zoxide zsh 7zip qbittorrent openssh-server zsh-syntax-highlighting zsh-autosuggestions yazi fd-find ripgrep wl-clipboard

# Chrome and VS Code .debs add their own apt repos for updates
install_deb google-chrome-stable https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
install_deb code "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"

# Not packaged for Ubuntu
mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
[ -d "$HOME/.local/share/powerlevel10k" ] ||
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.local/share/powerlevel10k"
[ -d "$HOME/.local/share/zsh-history-substring-search" ] ||
  git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "$HOME/.local/share/zsh-history-substring-search"

# Ubuntu ships bat as batcat and fd as fdfind
ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"

# ---------- Fonts ----------
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts"/* "$HOME/.local/share/fonts"
if [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz |
    tar -xJ -C "$HOME/.local/share/fonts/JetBrainsMono"
fi
fc-cache -f

# ---------- Dotfiles ----------
for f in .gitconfig .zshrc .p10k.zsh .tmux.conf; do
  ln -sf "$DOTFILES_DIR/config/$f" "$HOME/$f"
done

# ---------- ZSH ----------
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
  sudo chsh -s "$(command -v zsh)" "$USER"
fi

# ---------- Tmux ----------
sudo loginctl enable-linger "$USER"

echo "Main setup complete! Please RESTART your PC."
