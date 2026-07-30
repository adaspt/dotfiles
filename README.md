# Setup

Run `curl -fsSL https://raw.githubusercontent.com/adaspt/dotfiles/main/setup.sh | bash`

# Other useful commands

Create empty folder, copy files from ~/.ssh, remove/update whats needed, run commands:

```bash
tar -czvf ssh.tar.gz \*
age --passphrase --armor -o ssh.tar.gz.age ssh.tar.gz
```

dconf dump /
