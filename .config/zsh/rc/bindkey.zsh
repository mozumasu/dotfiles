
# ----------------------------------------------------
# Keybind
# ----------------------------------------------------

# Use emacs keybind
bindkey -e
# remove default keybind
bindkey -r "^X^F"

# fzf
zle -N fzf-history-widget
# bindkey '^R' fzf-history-widget  # Disabled: Using zeno-smart-history-selection instead

# ghq
zle -N ghq-fzf
bindkey '^g' ghq-fzf

# custom Ctrl+Z to suspend only when running in terminal
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

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

# bindkey '^U' push-line

# redo
bindkey '^X^R' redo
bindkey '^Xr' redo

# Debug: Show LBUFFER and RBUFFER
function show-buffer() {
  zle -M "LBUFFER: '$LBUFFER' | RBUFFER: '$RBUFFER'"
}
zle -N show-buffer
bindkey '^X^X' show-buffer
