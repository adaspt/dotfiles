# Setup

On a fresh Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/fedora/bootstrap.sh | bash
```

This installs git, clones the repo to `~/Projects/personal/dotfiles` and starts `./install`.

`./install` starts with a form: which steps to run. The answer is saved, so later runs skip the form. Then it runs the selected
steps in order and skips the ones already done.

Only the start needs you: the form, the OneDrive sign-in and the age passphrase. The rest runs
unattended, and steps don't stop for restarts: at the end it lists what needs one, and a single restart
covers all of it.

| Step       | What it does                                                                                        |
| ---------- | --------------------------------------------------------------------------------------------------- |
| `onedrive` | OneDrive client: sign in once in the browser, then syncs the folders in `config/onedrive/sync_list` |
| `ssh`      | Decrypts the SSH keys and VPN profile from `~/OneDrive/Backup` (asks for the age passphrase)        |
| `base`     | Upgrade, repos, packages, fonts, dotfiles, zsh, sysctl, boot log                                    |
| `hardware` | P14s Gen 4: NVIDIA off, no USB wakeup, xe driver. Other NVIDIA GPUs: driver                       |
| `gdm`      | Login screen: keeps its monitor layout in sync with yours, suspend settings as below                |
| `gnome`    | Extensions, settings from `config/gnome.ini`, suspend settings, wallpaper from `~/OneDrive/Backup` |
| `dev`      | Not selected by default. Development tools, Claude Code, Codex, T3 Code                             |
| `gaming`   | Not selected by default. Steam, GeForce NOW                                                         |

- `./install configure` shows the form again, then continues with newly ticked steps
- `./install STEP...` runs steps again, done or not
- `./install status` shows which steps are selected and done

# Layout

| Path        | Contents                                                                                    |
| ----------- | ------------------------------------------------------------------------------------------- |
| `install`   | Entry point; keeps the selected and finished steps in `~/.local/state/dotfiles/`             |
| `steps/`    | One script per step; each is safe to run again                                              |
| `lib/`      | Helpers: `needs_restart`, `install_packages`, `link`, `put`, `has_gpu`, `power_type`         |
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
