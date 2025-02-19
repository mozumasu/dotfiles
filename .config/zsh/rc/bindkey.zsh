
# ----------------------------------------------------
# Keybind
# ----------------------------------------------------

# Use emacs keybind
bindkey -e

# fzf
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget
bindkey '^g' ghq-fzf

# History search
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end

# Smart Insert Last Word
autoload smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
bindkey "^[." insert-last-word

# Edit Command Line
autoload edit-command-line
zle -N edit-command-line
bindkey "^[e" edit-command-line

bindkey '^U' push-line
