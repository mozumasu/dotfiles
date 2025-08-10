# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.pre.zsh"
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

# ----------------------------------------------------
# Function
# ----------------------------------------------------
source "$ZRCDIR/function.zsh"

# ----------------------------------------------------
# sheldon
# ----------------------------------------------------
# Manage shell plugins by sheldon
# https://sheldon.cli.rs/
eval "$(sheldon source)"

# ----------------------------------------------------
# Alias
# ----------------------------------------------------
source "$ZRCDIR/alias.zsh"

# ----------------------------------------------------
# SSH WezTerm integration
# ----------------------------------------------------
source "$ZRCDIR/ssh-wezterm.zsh"

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
# less
# ----------------------------------------------------
export LESSHISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/less/history"

# ----------------------------------------------------
# other
# ----------------------------------------------------

# Permissions when creating a new file
umask 022

# When zsh's completion candidates overflow from the screen, check whether they are still displayed.
export LISTMAX=50

# enable zmv
autoload -U zmv
alias mmv='noglob zmv -W'

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
# wezterm
# ----------------------------------------------------
source "$HOME/.config/zsh/rc/pluginconfig/wezterm.zsh"

# ----------------------------------------------------
# aws
# ----------------------------------------------------
source "$HOME/.config/zsh/rc/pluginconfig/aws.zsh"

# ----------------------------------------------------
# zeno.zsh
# ----------------------------------------------------
source "$HOME/.config/zsh/rc/pluginconfig/zeno.zsh"

# ----------------------------------------------------
# Neovim
# ----------------------------------------------------
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ----------------------------------------------------
# fzf
# ----------------------------------------------------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
# Disable fzf completion to use zeno completion
# source "/opt/homebrew/opt/fzf/shell/completion.zsh"
# key-bindings (default: /opt/homebrew/opt/fzf/shell/key-bindings.zsh)
source "$HOME/dotfiles/.config/zsh/rc/pluginconfig/fzf.key-bindings.zsh"

# ----------------------------------------------------
# starship
# ----------------------------------------------------
eval "$(starship init zsh)"

# ----------------------------------------------------
# Must be at the end of the file
# ----------------------------------------------------
eval "$(zoxide init zsh)"

# Amazon Q post block. Keep at the bottom of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/zshrc.post.zsh"
