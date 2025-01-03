# Setup fzf
# ---------
if [[ ! "$PATH" == */opt/homebrew/opt/fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/opt/homebrew/opt/fzf/bin"
fi

# Auto-completion
# ---------------
source "/opt/homebrew/opt/fzf/shell/completion.zsh"

# Key bindings
# ------------
# default
# source "/opt/homebrew/opt/fzf/shell/key-bindings.zsh"
# ------------
# my settings
source "$HOME/dotfiles/.config/zsh/fzf.key-bindings.zsh"
