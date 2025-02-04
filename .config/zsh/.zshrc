
# ----------------------------------------------------
# .zshrc
#
# initial setup file for only interactive zsh
# This file is read after .zshenv file is read.
#
# ----------------------------------------------------


# ----------------------------------------------------
# Keybind
# ----------------------------------------------------
source "$ZRCDIR/bindkey.zsh"

# ----------------------------------------------------
# homebrew
# ----------------------------------------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

# Manage shell plugins by sheldon
# https://sheldon.cli.rs/
eval "$(sheldon source)"

# ----------------------------------------------------
# Function
# ----------------------------------------------------
source "$ZRCDIR/function.zsh"

# ----------------------------------------------------
# Alias
# ----------------------------------------------------
source "$ZRCDIR/alias.zsh"

# ----------------------------------------------------
# Options
# ----------------------------------------------------
source "$ZRCDIR/option.zsh"

# ----------------------------------------------------
# History
# ----------------------------------------------------
export HISTFILE=${HOME}/.config/zsh/.zsh_history
# Limits memory-stored history
export HISTSIZE=100000
# Manage history persistence in files
export SAVEHIST=100000
export HISTFILESIZE=100000

# ----------------------------------------------------
# other
# ----------------------------------------------------

# Permissions when creating a new file
umask 022

# When zsh's completion candidates overflow from the screen, check whether they are still displayed.
export LISTMAX=50

# ----------------------------------------------------
# completion
# ----------------------------------------------------

autoload -Uz compinit && compinit
# 補完候補をそのまま探す -> 小文字を大文字に変えて探す -> 大文字を小文字に変えて探す
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'
# Group by completion method
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''
# Select a complementary candidate from the menu
# select=2: Select a completion candidate from the list, and if there are two or more completion candidates, it will be completed immediately.
zstyle ':completion:*:default' menu select=2

# ----------------------------------------------------
# zsh local settings
# ----------------------------------------------------
if [[ -d "$LOCAL_ZSH_DIR" ]]; then
  for file in "$LOCAL_ZSH_DIR"/*.zsh; do
    [ -r "$file" ] && source "$file"
  done
fi

# ----------------------------------------------------
# Neovim
# ----------------------------------------------------
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ----------------------------------------------------
# fzf
# ----------------------------------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget


# starship
eval "$(starship init zsh)"
# Must be at the end of the file
eval "$(zoxide init zsh)"
