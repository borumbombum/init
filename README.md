# init

Minimal environment bootstrap for a machine-agnostic developer. One curl command to feel at home anywhere.

## Supported Systems

- **omarchy** (Arch Linux)
- **Debian/Ubuntu**

## What it does

1. Installs **tmux**
2. Installs **Node.js** via nvm if not present
3. Installs **opencode-telegram-bot**
4. Installs **opencode**
5. Installs **fzf** (fuzzy finder for history)
6. Sets up portable **.zshrc** additions (aliases, history, NVM, RVM, bun, fzf, Powerlevel10k)
7. Installs custom Neovim configs
8. Creates a tmux session called `OpencodeBot` with two panes: telegram bot and opencode serve

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/borumbombum/init/main/bootstrap.sh | bash
```

Then attach to your session:
```bash
tmux attach -t OpencodeBot
```

## Backup

Secure encrypted backups of any directory using `backup.sh`.

### Download
```bash
curl -fsSL https://raw.githubusercontent.com/borumbombum/init/main/backup.sh -o backup.sh && chmod +x backup.sh
```

### Usage
```bash
./backup.sh <Source_Path> <Destination_Parent_Directory>
```

Example:
```bash
./backup.sh /Volumes/Pendrive/Data /home/user/Backups
```

The script syncs files from the source, compresses them into a tarball, encrypts it with AES-256-CBC (PBKDF2, 100k iterations), and automatically cleans up temporary files.

## Philosophy

You don't need your machine. You just need your curl command.
