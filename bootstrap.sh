#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — portable environment setup (macOS + Linux / WSL)
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
  case "$OSTYPE" in
    darwin*) echo "macos" ;;
    linux*)
      if   [[ -f /etc/arch-release ]];   then echo "arch"
      elif [[ -f /etc/debian_version ]]; then echo "debian"
      elif [[ -f /etc/fedora-release ]]; then echo "fedora"
      elif [[ -f /etc/alpine-release ]]; then echo "alpine"
      else                                    echo "linux"
      fi ;;
    *) err "Unsupported OS: $OSTYPE — this script supports macOS and Linux only." ;;
  esac
}

install_pkg() {
  local pkg="$1"
  log "Installing: $pkg"
  case "$OS" in
    macos)  brew install "$pkg" ;;
    arch)   sudo pacman -S --noconfirm --needed "$pkg" ;;
    debian) sudo apt-get install -y "$pkg" ;;
    fedora) sudo dnf install -y "$pkg" ;;
    alpine) sudo apk add --no-cache "$pkg" ;;
    linux)  err "Unknown Linux distro — install '$pkg' manually and re-run." ;;
  esac
}

OS=$(detect_os)
log "Detected OS: $OS"

# =============================================================================
# HOMEBREW  (macOS only — gate for all brew installs)
# =============================================================================
if [[ "$OS" == "macos" ]] && ! command -v brew &>/dev/null; then
  step "Homebrew"
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for Apple Silicon
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# =============================================================================
# 1. TMUX
# =============================================================================
step "1 / 4 — tmux"

if command -v tmux &>/dev/null; then
  log "tmux already installed ($(tmux -V))"
else
  install_pkg tmux
fi

# Config path: XDG for tmux >= 3.1, legacy ~/.tmux.conf for older
TMUX_MAJOR=$(tmux -V | grep -oE '[0-9]+' | head -1)
if [[ "$TMUX_MAJOR" -ge 3 ]]; then
  TMUX_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
  TMUX_CONF="$TMUX_CONF_DIR/tmux.conf"
  mkdir -p "$TMUX_CONF_DIR"
else
  TMUX_CONF="$HOME/.tmux.conf"
fi

log "Writing tmux config -> $TMUX_CONF"
cat > "$TMUX_CONF" << TMUXEOF
unbind r
bind r source-file $TMUX_CONF
set -g mouse on
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",xterm-256color:Tc"
set -g window-style 'bg=colour232'
set -g window-active-style 'bg=colour232'
set -g pane-border-style fg=white,bg=black
set -g pane-active-border-style fg=green,bg=black
set -g status-style bg=green,fg=black
TMUXEOF

log "tmux config written ✓"

# =============================================================================
# 2. NODE / NPM  (via nvm — avoids sudo, works on any distro)
# =============================================================================
step "2 / 4 — Node.js"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if command -v node &>/dev/null; then
  log "Node already installed ($(node -v))"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  log "Installing Node via nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm use --lts
fi

command -v npm &>/dev/null || err "npm not found after Node install — something went wrong."

# 3. OPENCODE TELEGRAM BOT
step "3 / 5 — opencode-telegram-bot"

if command -v opencode-telegram-bot &>/dev/null; then
  log "opencode-telegram-bot already installed ✓"
else
  log "Installing opencode-telegram-bot globally..."
  npm install -g @grinev/opencode-telegram-bot
  log "opencode-telegram-bot installed ✓"
fi

# =============================================================================
# 4. OPENCODE
# =============================================================================
step "4 / 5 — opencode"

if command -v opencode &>/dev/null; then
  log "opencode already installed ✓"
else
  log "Installing opencode..."
  curl -fsSL https://opencode.ai/install | bash
  log "opencode installed ✓"
fi

# =============================================================================
# 4. CAFFEINATE  (macOS built-in — skip on Linux)
# =============================================================================
step "4 / 4 — caffeinate"

if [[ "$OS" == "macos" ]]; then
  command -v caffeinate &>/dev/null && log "caffeinate available ✓" || warn "caffeinate not found."
else
  log "Linux — caffeinate not applicable, skipping."
fi

# =============================================================================
# 5. TMUX SESSION
# =============================================================================
step "5 / 5 — tmux session"

SESSION="OpencodeBot"
WIN="main"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "Session '$SESSION' already exists — skipping."
  warn "To recreate: tmux kill-session -t $SESSION && bash bootstrap.sh"
else
  log "Creating tmux session '$SESSION'..."

  # Create session — pane 0
  tmux new-session -d -s "$SESSION" -n "$WIN"

  # Pane 0: telegram bot
  tmux send-keys -t "$SESSION:$WIN.0" "opencode-telegram-bot" Enter

  # Pane 1: opencode serve
  tmux split-window -v -t "$SESSION:$WIN.0"
  tmux send-keys -t "$SESSION:$WIN.1" "opencode serve" Enter

  # Pane 2: caffeinate (macOS only)
  if [[ "$OS" == "macos" ]]; then
    tmux split-window -v -t "$SESSION:$WIN.1"
    tmux send-keys -t "$SESSION:$WIN.2" "caffeinate -d -u -s" Enter
  fi

  # Focus pane 0
  tmux select-pane -t "$SESSION:$WIN.0"

  log "Session '$SESSION' created ✓"
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GRN}  Bootstrap complete!${NC}"
echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Run this to attach:  ${BLU}tmux attach -t $SESSION${NC}"
echo ""
