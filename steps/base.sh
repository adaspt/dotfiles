# System upgrade, packages, fonts, dotfiles, shell and system tweaks.

sudo dnf upgrade -y --refresh

# ---------- Repos ----------
# Not in the Fedora repos: Ghostty and Yazi (COPR), Chrome (Google's repo, shipped disabled), VS Code (Microsoft's repo)
sudo dnf install -y dnf5-plugins fedora-workstation-repositories
sudo dnf copr enable -y scottames/ghostty
sudo dnf copr enable -y lihaohong/yazi
sudo dnf config-manager setopt google-chrome.enabled=1
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
put etc/yum.repos.d/vscode.repo

# ---------- Packages ----------
PACKAGES=(
  # Shell and terminal
  zsh zsh-syntax-highlighting zsh-autosuggestions ghostty tmux
  # CLI tools
  age bat btop eza fd-find fzf htop ripgrep yazi zoxide 7zip wl-clipboard
  # Apps and services
  code google-chrome-stable qbittorrent openssh-server flatpak
)
sudo dnf install -y "${PACKAGES[@]}"
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
# Microsoft fonts can't be in a public repo, so they come from OneDrive (synced by the onedrive step)
echo "Setting up fonts"
mkdir -p "$HOME/.local/share/fonts"
if [ -d "$HOME/OneDrive/Backup/fonts" ]; then
  cp -r "$HOME/OneDrive/Backup/fonts/." "$HOME/.local/share/fonts/"
else
  echo "~/OneDrive/Backup/fonts not found, skipping the Microsoft fonts."
fi
if [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMono"
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz |
    tar -xJ -C "$HOME/.local/share/fonts/JetBrainsMono"
fi
fc-cache -f

# ---------- Dotfiles ----------
link_home

# ---------- User ----------
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != */zsh ]]; then
  sudo usermod -s "$(command -v zsh)" "$USER"
fi
if [[ "$(getent passwd "$USER" | cut -d: -f5)" != "Adas Petrovas" ]]; then
  sudo usermod -c "Adas Petrovas" "$USER"
fi

# Remove the profile picture generated on first boot.
# An empty path makes AccountsService delete it, same as "Remove Picture" in GNOME Settings
gdbus call --system --dest org.freedesktop.Accounts --object-path "/org/freedesktop/Accounts/User$(id -u)" \
  --method org.freedesktop.Accounts.User.SetIconFile "" >/dev/null

# Keeps tmux sessions (and user services such as OneDrive) running after logout
sudo loginctl enable-linger "$USER"

# ---------- System ----------
put etc/sysctl.d/99-inotify.conf -- sudo sysctl --system --quiet

# Boot log instead of the Plymouth splash
sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"

needs_restart "new login shell, fonts and kernel arguments"
