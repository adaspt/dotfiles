#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/Projects/personal/dotfiles"

sudo dnf upgrade -y --refresh
sudo dnf install -y git curl dnf5-plugins

mkdir -p "$DOTFILES_DIR"
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  git clone -b fedora https://github.com/adaspt/dotfiles.git "$DOTFILES_DIR"
  git -C "$DOTFILES_DIR" remote set-url origin git@github.com:adaspt/dotfiles.git
fi

# Not in the Fedora repos: Ghostty and Yazi (COPR), Chrome (Google's repo, shipped disabled), VS Code (Microsoft's repo)
sudo dnf copr enable -y scottames/ghostty
sudo dnf copr enable -y lihaohong/yazi
sudo dnf install -y fedora-workstation-repositories
sudo dnf config-manager setopt google-chrome.enabled=1
if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  echo "[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
fi

sudo dnf install -y age eza fzf bat ghostty htop btop tmux zoxide zsh 7zip qbittorrent openssh-server zsh-syntax-highlighting zsh-autosuggestions yazi fd-find ripgrep wl-clipboard flatpak google-chrome-stable code
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Fedora doesn't start sshd on install
sudo systemctl enable --now sshd

# Not packaged for Fedora
mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
[ -d "$HOME/.local/share/powerlevel10k" ] ||
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.local/share/powerlevel10k"
[ -d "$HOME/.local/share/zsh-history-substring-search" ] ||
  git clone --depth=1 https://github.com/zsh-users/zsh-history-substring-search.git "$HOME/.local/share/zsh-history-substring-search"

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
mkdir -p "$HOME/.claude"
ln -sf "$DOTFILES_DIR/config/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$DOTFILES_DIR/config/settings.json" "$HOME/.claude/settings.json"

# ---------- ZSH ----------
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
  sudo usermod -s "$(command -v zsh)" "$USER"
fi

# ---------- Tmux ----------
sudo loginctl enable-linger "$USER"

# ---------- inotify limits (large OneDrive trees, dev file watchers such as dotnet watch) ----------
if [ ! -f /etc/sysctl.d/99-inotify.conf ]; then
  echo 'fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=1024' | sudo tee /etc/sysctl.d/99-inotify.conf >/dev/null
  sudo sysctl --system >/dev/null
fi

# ---------- Boot log instead of the Plymouth splash ----------
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"

# ---------- Remove the profile picture generated on first boot ----------
# An empty path makes AccountsService delete it, same as "Remove Picture" in GNOME Settings
gdbus call --system --dest org.freedesktop.Accounts --object-path "/org/freedesktop/Accounts/User$(id -u)" \
  --method org.freedesktop.Accounts.User.SetIconFile "" >/dev/null

echo "Main setup complete! Please RESTART your PC."
