# if defined load the configuration file from there
export ZENO_HOME=~/.config/zeno

# if disable deno cache command when plugin loaded
# export ZENO_DISABLE_EXECUTE_CACHE_COMMAND=1

# if enable fzf-tmux
# export ZENO_ENABLE_FZF_TMUX=1

# if setting fzf-tmux options
# export ZENO_FZF_TMUX_OPTIONS="-p"

# Experimental: Use UNIX Domain Socket
export ZENO_ENABLE_SOCK=1

# if disable builtin completion
# export ZENO_DISABLE_BUILTIN_COMPLETION=1

# default: cat
export ZENO_GIT_CAT="bat --color=always"

# default: tree
export ZENO_GIT_TREE="exa --tree"

if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet

  # fallback if snippet not matched (default: self-insert)
  # export ZENO_AUTO_SNIPPET_FALLBACK=self-insert

  # if you use zsh's incremental search
  # bindkey -M isearch ' ' self-insert

  bindkey '^m' zeno-auto-snippet-and-accept-line

  bindkey '^i' zeno-completion

  bindkey '^x '  zeno-insert-space

  # Run the current command line without snippet expansion
  bindkey '^x^m' accept-line
  # Toggle automatic snippet expansion on and off
  bindkey '^x^z' zeno-toggle-auto-snippet

  # fallback if completion not matched
  # (default: fzf-completion if exists; otherwise expand-or-complete)
  # export ZENO_COMPLETION_FALLBACK=expand-or-complete
 
  # bindkey '^r'   zeno-history-selection
  bindkey '^r' zeno-smart-history-selection
  bindkey '^x^s' zeno-insert-snippet
  bindkey '^x^f' zeno-snippet-next-placeholder
  bindkey "^X^[[C" zeno-snippet-next-placeholder
  # bindkey '^x^f' zeno-ghq-cd
fi
