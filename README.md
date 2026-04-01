# init

Minimal environment bootstrap for a machine-agnostic developer. One curl command to feel at home anywhere.

## What it does

1. Installs **tmux** with a sane config
2. Installs **Node.js** via nvm if not present
3. Installs **opencode**
4. Installs **caffeinate** (macOS only)
5. Creates a tmux session called `OpencodeBot` with the telegram bot running inside it

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/borumbumbum/init/main/bootstrap.sh | bash
```

Then attach to your session:

```bash
tmux attach -t OpencodeBot
```

## Compatibility

| OS | Supported |
|---|---|
| macOS | ✓ |
| Arch Linux | ✓ |
| Debian / Ubuntu | ✓ |
| Fedora | ✓ |
| Alpine | ✓ |
| WSL | ✓ |
| Windows | ✗ |

## Philosophy

You don't need your machine. You just need your curl command.
