# init

Minimal environment bootstrap for a machine-agnostic developer. One curl command to feel at home anywhere.

## What it does

1. Installs **tmux** with a sane config
2. Installs **Node.js** via nvm if not present
3. Installs **opencode**
4. Installs **caffeinate** (macOS only)
5. Creates a tmux session called `OpencodeBot` with three panes: telegram bot, opencode serve, and caffeinate

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

The script syncs files from the source, compresses them into a tarball, encrypts it with AES-256-CBC, and automatically cleans up temporary files.

## Philosophy

You don't need your machine. You just need your curl command.
