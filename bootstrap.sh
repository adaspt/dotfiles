#!/usr/bin/env bash
# First thing to run on a fresh install: clones this repo and starts ./install.
#   curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/fedora/bootstrap.sh | bash
set -euo pipefail

# Everything is inside main, called on the last line: if the download is cut off, nothing runs
main() {
  local dotfiles_dir="$HOME/Projects/personal/dotfiles"

  sudo dnf install -y git

  if [ ! -d "$dotfiles_dir/.git" ]; then
    mkdir -p "$(dirname "$dotfiles_dir")"
    # Stays an HTTPS remote: pulls need no key, and .gitconfig sends pushes over SSH
    git clone -b fedora https://github.com/adaspt/dotfiles.git "$dotfiles_dir"
  fi

  # Piped into bash, stdin is the script itself; the install prompts need the terminal
  exec "$dotfiles_dir/install" < /dev/tty
}

main "$@"
