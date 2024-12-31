# ----------------------------------------------------
# .zshenv
#
# initial setup file for both interactive and noninteractive zsh
#
# ----------------------------------------------------

# Disable loading of global configuration files
unsetopt GLOBAL_RCS

# XDG
export XDG_CONFIG_HOME=${HOME}/.config
export XDG_CACHE_HOME=${HOME}/.cache
export XDG_DATA_HOME=${HOME}/.local/share
export XDG_STATE_HOME=${HOME}/.local/state

# zsh
export ZDOTDIR=${XDG_CONFIG_HOME}/zsh

# path
export PATH=${HOME}/.local/bin:$PATH
export PATH="/usr/local/sbin:$PATH"

# lang
export LANGUAGE="en_US.UTF-8"
export LANG="${LANGUAGE}"
export LC_ALL="${LANGUAGE}"
export LC_CTYPE="${LANGUAGE}"

# editor
export EDITOR=nvim
export CVSEDITOR="${EDITOR}"
export SVN_EDITOR="${EDITOR}"
export GIT_EDITOR="${EDITOR}"

# ----------------------------------------------------

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GO111MODULE="on"
