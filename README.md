# Setup

On a fresh Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/fedora/bootstrap.sh | bash
```

This installs git, clones the repo to `~/Projects/personal/dotfiles` and starts `./install`.

`./install` runs the steps below in order and skips the ones already done. When a step needs a
restart it stops; restart and run `~/Projects/personal/dotfiles/install` again to continue.

| Step       | What it does                                                                                        |
| ---------- | --------------------------------------------------------------------------------------------------- |
| `hostname` | Asks for the PC name                                                                                |
| `base`     | Upgrade, repos, packages, fonts, dotfiles, zsh, sysctl, boot log. Restart                           |
| `hardware` | Detects the hardware. Laptop: NVIDIA off, no USB wakeup, Intel xe driver. Desktop: NVIDIA driver    |
| `gdm`      | Login screen: copies the monitor layout (configure monitors first), disables suspend                |
| `ssh`      | Asks you to download the SSH keys and VPN profile in Chrome, then decrypts and installs them        |
| `gnome`    | Extensions and settings from `config/gnome.ini`. Log out and back in                                |

Optional steps: `./install dev`, `./install onedrive`, `./install gaming`.

- `./install STEP...` runs steps again, done or not
- `./install status` shows which steps are done

Still manual: set the wallpaper.

# Layout

| Path        | Contents                                                                                    |
| ----------- | ------------------------------------------------------------------------------------------- |
| `install`   | Entry point; tracks finished steps in `~/.local/state/dotfiles/`                             |
| `steps/`    | One script per step; each is safe to run again                                              |
| `lib/`      | Helpers: `ask`, `confirm`, `needs_restart`, `install_packages`, `link`, `put`, `has_gpu`     |
| `packages/` | dnf package lists, one per line                                                             |
| `config/`   | Dotfiles, symlinked into `~` by the base step; `gnome.ini` is loaded with `dconf load /`     |
| `files/`    | System files, mirroring `/`, copied into place by `put` (e.g. `files/etc/sysctl.d/...`)      |
| `fonts/`    | Fonts copied to `~/.local/share/fonts`                                                      |

GNOME settings: change something in Settings, find the key with `dconf watch /` (or `dconf dump /`), and
copy it into `config/gnome.ini`.

# Other useful commands

Create empty folder, copy files from ~/.ssh, remove/update whats needed, run commands:

```bash
tar -czvf ssh.tar.gz *
age --passphrase --armor -o ssh.tar.gz.age ssh.tar.gz
```

dconf dump /
