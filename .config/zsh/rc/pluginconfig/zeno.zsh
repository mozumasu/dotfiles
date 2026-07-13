# if defined load the configuration file from there
export ZENO_HOME=~/.config/zeno

# Experimental: Use UNIX Domain Socket
export ZENO_ENABLE_SOCK=1

export ZENO_GIT_CAT="bat --color=always"
export ZENO_GIT_TREE="eza --tree"

if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet

  bindkey '^m' zeno-auto-snippet-and-accept-line

  bindkey '^i' zeno-completion

  bindkey '^x '  zeno-insert-space

  # Run the current command line without snippet expansion
  bindkey '^x^m' accept-line
  # Toggle automatic snippet expansion on and off
  bindkey '^x^z' zeno-toggle-auto-snippet

  bindkey '^r' zeno-smart-history-selection
  bindkey '^x^s' zeno-insert-snippet
  bindkey '^x^f' zeno-snippet-next-placeholder
  bindkey "^X^[[C" zeno-snippet-next-placeholder
fi
