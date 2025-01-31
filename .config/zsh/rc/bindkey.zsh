
# ----------------------------------------------------
# Keybind
# ----------------------------------------------------

# Use emacs keybind
bindkey -e
bindkey '^g' ghq-fzf
# history search
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
