# Setup

On a fresh Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/fedora/bootstrap.sh | bash
```

This installs git, clones the repo to `~/Projects/personal/dotfiles` and starts `./install`.

`./install` starts with a form: which steps to run. The answer is saved, so later runs skip the form.
Then it runs the selected steps in order and skips the ones already done.

Only the start needs you: the form, the OneDrive sign-in and the age passphrase (once). The rest runs
unattended, and steps don't stop for restarts: at the end it lists what needs one, and a single restart
covers all of it.

| Step       | What it does                                                                                        |
| ---------- | --------------------------------------------------------------------------------------------------- |
| `onedrive` | OneDrive client: sign in once in the browser, then syncs the folders in `config/onedrive/sync_list` |
| `ssh`      | SSH keys from the secrets archive in `~/OneDrive/Backup` (asks for the age passphrase once)         |
| `vpn`      | WireGuard connection `agersi-vpn` from the same archive, not connected automatically                |
| `base`     | Upgrade, repos, packages, fonts (from `~/OneDrive/Backup/fonts`), dotfiles, zsh, sysctl, boot log   |
| `hardware` | P14s Gen 4: NVIDIA off, no USB wakeup, xe driver. Other NVIDIA GPUs: driver                         |
| `gnome`    | Extensions, `config/gnome.ini`, suspend and monitor layout also for the login screen, wallpaper     |
| `agents`   | Claude Code, Codex CLI, T3 Code                                                                     |
| `dev`      | Not selected by default. Azure CLI, .NET SDK, nvm with Node.js 24                                   |
| `gaming`   | Not selected by default. Steam, GeForce NOW                                                         |

- `./install configure` shows the form again, then continues with newly ticked steps
- `./install STEP...` runs steps again, done or not
- `./install status` shows which steps are selected and done

# Layout

| Path               | Contents                                                                                |
| ------------------ | --------------------------------------------------------------------------------------- |
| `install`          | Entry point; keeps the selected and finished steps in `~/.local/state/dotfiles/`        |
| `steps/`           | One script per step; each is safe to run again                                          |
| `lib/`             | Helpers: `unlock_secrets`, `needs_restart`, `link_home`, `put`, `has_gpu`, `power_type` |
| `config/home/`     | Mirrors `~`: every file is symlinked to the same path by the base step                  |
| `config/system/`   | Mirrors `/`: copied as root by `put`, only the files a step names                       |
| `config/gnome.ini` | GNOME settings, loaded with `dconf load /` by the gnome step                            |
| `config/onedrive/` | OneDrive client config, copied once by the onedrive step                                |

GNOME settings: change something in Settings, find the key with `dconf watch /` (or `dconf dump /`), and
copy it into `config/gnome.ini`.

# Other useful commands

Update the secrets archive (the ssh and vpn steps read it): put what goes into `~/.ssh` into `ssh/`, add the
WireGuard profile, encrypt with a passphrase straight into OneDrive, then delete the plain copies:

```bash
mkdir -p ~/secrets/ssh && cd ~/secrets
cp ~/.ssh/id_* ~/.ssh/config ~/.ssh/known_hosts ~/.ssh/authorized_keys ssh/
cp /path/to/agersi-vpn.conf .
tar -czf - ssh agersi-vpn.conf | age --passphrase --armor -o ~/OneDrive/Backup/secrets.tar.gz.age
cd ~ && rm -rf ~/secrets
```
