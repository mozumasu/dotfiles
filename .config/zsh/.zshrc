#!/bin/zsh
# oh-my-zshをインストールしたパス
export ZSH="$HOME/.oh-my-zsh"

# oh-my-zshでロードするプラグインの設定
plugins=(git z web-search fzf rye)

source $ZSH/oh-my-zsh.sh

# ryeのプラグインを読み込む
export PATH=$PATH:$HOME/.rye/shims

export PATH=$PATH:$HOME/Library/Python/2.7/bin
# 共通設定ファイル読み込み
RC_COMMON=$HOME/dotfiles/.bin/.rc_common

if [ -e $RC_COMMON ]
then source $RC_COMMON
else
    echo "$RC_COMMON not found."
fi

# 新規ファイル作成時のパーミッション
umask 022

# homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# antigen
source $HOME/.local/bin/antigen.zsh

# Load the oh-my-zsh's library
antigen use oh-my-zsh

antigen bundles <<EOBUNDLES
    # Bundles from the default repo (robbyrussell's oh-my-zsh)
    git
    # Syntax highlighting bundle.
    zsh-users/zsh-syntax-highlighting
    # Fish-like auto suggestions
    zsh-users/zsh-autosuggestions
    # Extra zsh completions
    zsh-users/zsh-completions
    # z
mkdir $ZSH_CUSTOM/plugins/rye
rye self completion -s zsh > $ZSH_CUSTOM/plugins/rye/_rye
    rupa/z z.sh
    # abbr
    olets/zsh-abbr@main
EOBUNDLES

# Load the theme
antigen theme robbyrussell

# Tell antigen that you're done
antigen apply

# starship
eval "$(starship init zsh)"

# alias
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias ls='ls -F --color=auto'
alias mul='multipass'
abbr -S ll='ls -l' >>/dev/null
abbr -S la='ls -A' >>/dev/null
abbr -S lla='ls -l -A' >>/dev/null
abbr -S v='vim' >>/dev/null
abbr -S g='git' >>/dev/null
abbr -S gst='git status' >>/dev/null
abbr -S gsw='git switch' >>/dev/null
abbr -S gbr='git branch' >>/dev/null
abbr -S gfe='git fetch' >>/dev/null
abbr -S gpl='git pull' >>/dev/null
abbr -S gad='git add' >>/dev/null
abbr -S gcm='git commit' >>/dev/null
abbr -S gmg='git merge' >>/dev/null
abbr -S gpsh='git push' >>/dev/null
abbr -S lg='lazygit' >>/dev/null

# volta ここに記載しないと読み込めない
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# zshのみの独自設定
# cd時に自動でスタック
setopt auto_pushd
# スタックを重複させない
setopt pushd_ignore_dups
# cd無しで指定したパスへ移動
setopt auto_cd
# historyを重複させない
setopt hist_ignore_dups
setopt share_history
# 即座に履歴を保存
setopt inc_append_history

# zshのHistory設定
export HISTFILE=~/.config/zsh/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000
# zshの補完設定
autoload -Uz compinit && compinit
# 補完候補をそのまま探す -> 小文字を大文字に変えて探す -> 大文字を小文字に変えて探す
zstyle ':completion:*' matcher-list '' 'm:{[:lower:]}={[:upper:]}' '+m:{[:upper:]}={[:lower:]}'
# 補完方法毎にグループ化
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''
# 補完侯補をメニューから選択
# select=2: 補完候補を一覧から選択,補完候補が2つ以上なければすぐに補完
zstyle ':completion:*:default' menu select=2

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
