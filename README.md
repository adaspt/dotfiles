# Setup

- bash -c "$(wget -qO- https://raw.githubusercontent.com/adaspt/dotfiles/fedora/setup.sh)"
- setup-hostname
- Restart
- For laptop disable nvidia and wakeup, setup-intel
- For PC with nvidia card setup-nvidia
- Restart
- Configure monitors
- setup-gdm-greeter
- Open chrome and download secrets
- setup-ssh
- Restart
- setup-gnome
- Restart
- Enable extensions
- sudo usermod -c "Adas Petrovas" $USER
- Set wallpaper
- If needed - install development frameworks
- setup-onedrive

# Other useful commands

Create empty folder, copy files from ~/.ssh, remove/update whats needed, run commands:

```bash
tar -czvf ssh.tar.gz *
age --passphrase --armor -o ssh.tar.gz.age ssh.tar.gz
```

dconf dump /
