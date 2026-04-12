alias ls='ls -ealth'
alias ll='/bin/ls -lth'
alias lse='/bin/ls -lht | sort -rs -t. -k2'

bindkey '^[[A' fzf-history-widget
bindkey '^R' fzf-history-widget

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"