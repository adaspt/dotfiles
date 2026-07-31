# Setup

- bash -c "$(curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/main/setup.sh)"
- Restart
- For laptop disable nvidia and wakeup
- Restart
- Configure monitors
- setup-gdm-greeter
- Open chrome and download secrets
- setup-ssh
- Restart
- setup-gnome
- Restart
- Enable extensions
- sudo chfn -f "Adas Petrovas" $USER
- Set wallpaper
- Show hidden files and sort directories first on Nautilus
- If needed - install development frameworks

# Other useful commands

Create empty folder, copy files from ~/.ssh, remove/update whats needed, run commands:

```bash
tar -czvf ssh.tar.gz \*
age --passphrase --armor -o ssh.tar.gz.age ssh.tar.gz
```

dconf dump /
