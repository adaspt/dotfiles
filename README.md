# Setup

On a fresh Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/fedora/bootstrap.sh | bash
```

This installs git, clones the repo to `~/Projects/personal/dotfiles` and starts `./install`.

`./install` runs the steps below in order and skips the ones already done. Steps don't stop for
restarts: at the end it lists what needs one, and a single restart covers all of it.

| Step       | What it does                                                                                        |
| ---------- | --------------------------------------------------------------------------------------------------- |
| `hostname` | Asks for the PC name                                                                                |
| `base`     | Upgrade, repos, packages, fonts, dotfiles, zsh, sysctl, boot log                                    |
| `hardware` | Detects the hardware. Laptop: NVIDIA off, no USB wakeup, Intel xe driver. Desktop: NVIDIA driver    |
| `gdm`      | Login screen: keeps its monitor layout in sync with yours, disables suspend                         |
| `onedrive` | OneDrive client: sign in once in the browser, then syncs the folders in `config/onedrive/sync_list` |
| `ssh`      | Decrypts the SSH keys and VPN profile from `~/OneDrive/Backup` (asks for the age passphrase)        |
| `gnome`    | Extensions, settings from `config/gnome.ini`, wallpaper from `~/OneDrive/Backup`                    |

Optional steps: `./install dev`, `./install gaming`.

- `./install STEP...` runs steps again, done or not
- `./install status` shows which steps are done

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

Then upload `ssh.tar.gz.age` to the `Backup` folder in OneDrive.

dconf dump /
