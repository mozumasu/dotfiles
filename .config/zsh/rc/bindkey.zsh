
# ----------------------------------------------------
# Keybind
# ----------------------------------------------------

# Use emacs keybind
bindkey -e
# remove default keybind
bindkey -r "^X^F"

# fzf
zle -N fzf-history-widget

# ghq
zle -N ghq-fzf
bindkey '^g' ghq-fzf

# ghq readme search
zle -N ghq-fzf-readme
bindkey '^X^G' ghq-fzf-readme

# custom Ctrl+Z to suspend only when running in terminal
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# History search
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^p" history-beginning-search-backward-end
bindkey "^n" history-beginning-search-forward-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end

# zsh-autosuggestions にラップさせないウィジェット。
# insert-last-word と copy-earlier-word は連続押下の判定に自身の名前と内部状態を使うため、
# ラップされると毎回リセットされる。この変数を定義するとプラグイン側のデフォルトは適用されない。
ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
  orig-\* beep run-help set-local-history which-command yank yank-pop zle-\*
  insert-last-word copy-earlier-word
)

# Smart Insert Last Word
autoload smart-insert-last-word
zle -N insert-last-word smart-insert-last-word
bindkey "^[." insert-last-word

# Copy Earlier Word: ^[. で入れた単語を同じ履歴行内で 1 つずつ前に差し替える
# ^[, は遅延実行される compinit に上書きされるため、init.nix の _deferred_compinit でも張り直す
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
bindkey "^[," copy-earlier-word

# Edit Command Line
autoload edit-command-line
zle -N edit-command-line
bindkey "^[e" edit-command-line

# redo
bindkey '^X^R' redo
bindkey '^Xr' redo

# Debug: Show LBUFFER and RBUFFER
function show-buffer() {
  zle -M "LBUFFER: '$LBUFFER' | RBUFFER: '$RBUFFER'"
}
zle -N show-buffer
bindkey '^X^X' show-buffer
