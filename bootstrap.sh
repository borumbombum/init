#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — omarchy (Arch Linux) + Debian/Ubuntu environment setup
# curl -fsSL https://raw.githubusercontent.com/borumbombum/init/main/bootstrap.sh | bash
# =============================================================================
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; BLU='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${GRN}[bootstrap]${NC} $1"; }
warn() { echo -e "${YLW}[warn]${NC} $1"; }
err()  { echo -e "${RED}[error]${NC} $1"; exit 1; }
step() { echo -e "\n${BLU}── $1${NC}"; }

# ── OS Detection ──────────────────────────────────────────────────────────────
detect_os() {
  if [[ -f /etc/arch-release ]]; then
    echo "arch"
  elif [[ -f /etc/debian_version ]]; then
    echo "debian"
  else
    echo "Unsupported OS. This script supports omarchy (Arch Linux) and Debian/Ubuntu only." >&2
    exit 1
  fi
}

install_pkg() {
  local pkg="$1"
  local use_sudo=""
  if command -v sudo &>/dev/null && [[ $EUID -ne 0 ]]; then
    use_sudo="sudo"
  fi
  log "Installing: $pkg"
  case "$OS" in
    arch)   $use_sudo pacman -S --noconfirm --needed "$pkg" ;;
    debian) $use_sudo apt-get install -y "$pkg" ;;
    *)     err "Cannot install '$pkg' — unsupported OS: $OS" ;;
  esac
}

declare -A CONFIG_DESTINATIONS=(
  ["nvim-config"]="$HOME/.config/nvim/lua/config"
  ["omarchy-themes"]="$HOME/.config/omarchy/themes"
)

clone_configs() {
  set +u
  CLONE_DIR=$(mktemp -d)

  log "Cloning configs..."
  if ! git clone --depth 1 https://github.com/borumbombum/init.git "$CLONE_DIR" 2>/dev/null; then
    err "Failed to clone configs repo"
  fi

  local config_src="$CLONE_DIR/configs"

  for folder in "$config_src"/*; do
    [[ -e "$folder" ]] || continue
    local folder_name
    folder_name=$(basename "$folder")

    # Skip zsh - handled separately in step 7
    [[ "$folder_name" == "zsh" ]] && continue

    local dest="${CONFIG_DESTINATIONS[$folder_name]:-}"

    if [[ -z "$dest" ]]; then
      warn "No destination defined for $folder_name — skipping"
      continue
    fi

    if [[ -e "$dest" ]]; then
      warn "$dest already exists."
      if [ -t 0 ]; then
        read -p "Overwrite? [y/N] " -n 1 -r reply < /dev/tty; echo
      else
        warn "Non-interactive run — skipping $folder_name"
        continue
      fi
      if [[ ! $reply =~ ^[Yy]$ ]]; then
        log "Skipped $folder_name"
        continue
      fi
    fi

    mkdir -p "$dest"
    cp -r "$folder"/* "$dest/"
    log "Copied $folder_name -> $dest"
  done
  set -u
}

OS=$(detect_os)
log "Detected OS: $OS"

# =============================================================================
# 1. TMUX
# =============================================================================
step "1 / 8 — tmux"

if command -v tmux &>/dev/null; then
  log "tmux already installed ($(tmux -V))"
else
  install_pkg tmux
fi

# =============================================================================
# 2. NODE / NPM  (via nvm — avoids sudo, works on any distro)
# =============================================================================
step "2 / 8 — Node.js"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if command -v node &>/dev/null; then
  log "Node already installed ($(node -v))"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  log "Installing Node via nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  (
    set +u
    nvm install --lts
    nvm use --lts
  )
fi

command -v npm &>/dev/null || err "npm not found after Node install — something went wrong."

# =============================================================================
# 3. OPENCODE TELEGRAM BOT
# =============================================================================
step "3 / 8 — opencode-telegram-bot"

if opencode-telegram --version &>/dev/null 2>&1; then
  log "opencode-telegram-bot already installed ✓"
else
  log "Installing opencode-telegram-bot globally..."
  npm install -g @grinev/opencode-telegram-bot
  log "opencode-telegram-bot installed ✓"
fi

# =============================================================================
# 4. OPENCODE
# =============================================================================
step "4 / 8 — opencode"

if opencode --version &>/dev/null 2>&1; then
  log "opencode already installed ✓"
else
  log "Installing opencode..."
  curl -fsSL https://opencode.ai/install | bash
  log "opencode installed ✓"
fi

# =============================================================================
# 5. FZF
# =============================================================================
step "5 / 8 — fzf"

if command -v fzf &>/dev/null; then
  log "fzf already installed ✓"
else
  install_pkg fzf
fi

# =============================================================================
# 6. CUSTOM CONFIGS
# =============================================================================
step "6 / 8 — Custom Configs"

clone_configs

# =============================================================================
# 7. ZDOTDIR / .zshrc SETUP
# =============================================================================
step "7 / 8 — zsh environment"

if [[ "$SHELL" != */zsh ]]; then
  warn "zsh not detected — skipping zsh configuration"
elif grep -q 'source.*\.zshrc.d/custom.sh' "$HOME/.zshrc" 2>/dev/null; then
  log "zsh environment already configured ✓"
else
  log "Setting up zsh environment..."
  mkdir -p "$HOME/.zshrc.d"

  cp "$CLONE_DIR/configs/zsh/custom.sh" "$HOME/.zshrc.d/custom.sh"

  echo '' >> "$HOME/.zshrc"
  echo '# bootstrap.sh customizations' >> "$HOME/.zshrc"
  echo '[[ -f ~/.zshrc.d/custom.sh ]] && source ~/.zshrc.d/custom.sh' >> "$HOME/.zshrc"

  log "zsh environment set up ✓"
fi

# =============================================================================
# 8. TMUX SESSION
# =============================================================================
step "8 / 8 — tmux session"

SESSION="OpencodeBot"
WIN="main"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "Session '$SESSION' already exists."
  warn "To recreate: tmux kill-session -t $SESSION && re-run bootstrap."
else
  log "Creating session '$SESSION'..."

  tmux new-session -d -s "$SESSION" -n "$WIN"

  tmux send-keys -t "$SESSION:$WIN.0" "opencode-telegram start" Enter

  tmux split-window -v -t "$SESSION:$WIN.0"
  tmux send-keys -t "$SESSION:$WIN.1" "opencode serve" Enter

  tmux select-pane -t "$SESSION:$WIN.0"
  log "Session '$SESSION' created ✓"
fi

rm -rf "$CLONE_DIR" 2>/dev/null

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN}  Bootstrap complete!${NC}"
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BLU}tmux attach -t $SESSION${NC}"
echo ""