# ----------------------------------------------------
# .zshrc
#
# initial setup file for only interactive zsh
# This file is read after .zshenv file is read.
#
# ----------------------------------------------------

# ----------------------------------------------------
# zcompile - Compile zsh files for faster loading
# ----------------------------------------------------
# Compile zsh file if not compiled or source is newer
function ensure_zcompiled {
  local src=$1
  local zwc="$src.zwc"
  if [[ ! -r "$zwc" || "$src" -nt "$zwc" ]]; then
    zcompile "$src"
  fi
}

# Override source to auto-compile
function source {
  ensure_zcompiled "$1"
  builtin source "$1"
}

# ----------------------------------------------------
# homebrew
# ----------------------------------------------------
# eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_PREFIX="/opt/homebrew";
export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
export HOMEBREW_REPOSITORY="/opt/homebrew";
fpath[1,0]="/opt/homebrew/share/zsh/site-functions";
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";

# Prioritize Japanese man pages
export MANPATH="/usr/local/share/man/ja_JP.UTF-8:$(manpath)"

# ----------------------------------------------------
# mise
# ----------------------------------------------------
if type mise &>/dev/null; then
  _mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/mise.zsh"
  if [[ ! -r "$_mise_cache" || "$(command -v mise)" -nt "$_mise_cache" ]]; then
    mise activate zsh > "$_mise_cache"
    mise activate --shims >> "$_mise_cache"
    zcompile "$_mise_cache"
  fi
  source "$_mise_cache"
  unset _mise_cache
fi

# ----------------------------------------------------
# Function
# ----------------------------------------------------
# Add functions directory and all subdirectories to the fpath
fpath=($ZRCDIR/functions $ZRCDIR/functions/*(/N) $fpath)

# Autoload all Files and symlinks (exclude directories)
autoload -Uz $ZRCDIR/functions/*(-.N:t) $ZRCDIR/functions/**/*(-.N:t)

# ----------------------------------------------------
# Keybind
# ----------------------------------------------------
source "$ZRCDIR/bindkey.zsh"
# ----------------------------------------------------
# sheldon
# ----------------------------------------------------
# Manage shell plugins by sheldon
# https://sheldon.cli.rs/
# eval "$(sheldon source)"

# Storing file names in a variable
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
sheldon_cache="$cache_dir/sheldon.zsh"
sheldon_toml="$HOME/.config/sheldon/plugins.toml"
# Create cache when cache is missing or outdated
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
  mkdir -p $cache_dir
  sheldon source > "$sheldon_cache"
  zcompile "$sheldon_cache"
fi
source "$sheldon_cache"
# Remove variables that are no longer needed
unset cache_dir sheldon_cache sheldon_toml

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

# Use -C to skip security check for faster startup
# Completions are auto-refreshed by brew function wrapper
autoload -Uz compinit && compinit -C
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
zsh-defer -a source "$HOME/.config/zsh/rc/pluginconfig/wezterm.zsh"

# ----------------------------------------------------
# zeno.zsh
# ----------------------------------------------------
source "$HOME/.config/zsh/rc/pluginconfig/zeno.zsh"

# ----------------------------------------------------
# fzf
# ----------------------------------------------------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi
# Disable fzf completion to use zeno completion
# source "/opt/homebrew/opt/fzf/shell/completion.zsh"
# key-bindings (default: /opt/homebrew/opt/fzf/shell/key-bindings.zsh)
zsh-defer source "$HOME/dotfiles/.config/zsh/rc/pluginconfig/fzf.key-bindings.zsh"

# ----------------------------------------------------
# starship
# ----------------------------------------------------
_starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship.zsh"
_starship_config="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
if [[ ! -r "$_starship_cache" || "$_starship_config" -nt "$_starship_cache" || "$(command -v starship)" -nt "$_starship_cache" ]]; then
  starship init zsh > "$_starship_cache"
  zcompile "$_starship_cache"
fi
source "$_starship_cache"
unset _starship_cache _starship_config

# ----------------------------------------------------
# zoxide (Must be at the end of the file)
# ----------------------------------------------------
_zoxide_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide.zsh"
if [[ ! -r "$_zoxide_cache" || "$(command -v zoxide)" -nt "$_zoxide_cache" ]]; then
  zoxide init zsh > "$_zoxide_cache"
  zcompile "$_zoxide_cache"
fi
source "$_zoxide_cache"
unset _zoxide_cache

source ~/.safe-chain/scripts/init-posix.sh # Safe-chain Zsh initialization script
