# Development tools, on some machines only: Azure CLI, .NET SDK, nvm with Node.js 24.

# ---------- Repos ----------
# Azure CLI: Microsoft's RHEL 10 repo, Fedora's package lags behind
rpm -q packages-microsoft-prod &> /dev/null || {
  sudo rpm --import https://packages.microsoft.com/keys/microsoft-2025.asc
  sudo dnf install -y https://packages.microsoft.com/config/rhel/10/packages-microsoft-prod.rpm
}

sudo dnf install -y azure-cli dotnet-sdk-10.0

# ---------- nvm (PROFILE=/dev/null: .zshrc already loads it) and Node.js 24 ----------
[ -d "$HOME/.nvm" ] || curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE=/dev/null bash
# In its own bash: nvm isn't written for set -euo pipefail. Installs the latest 24.x, or keeps it if
# already there, and makes it the default for new shells
bash -c 'source "$HOME/.nvm/nvm.sh" && nvm install 24 && nvm alias default 24'
