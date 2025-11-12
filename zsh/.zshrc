autoload -Uz compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

source $ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZDOTDIR/alias.sh

PROMPT="[%n] %~ %# "
RPROMPT="%D | %*"

. "$HOME/.local/share/../bin/env"
eval "$(uv generate-shell-completion zsh)"
