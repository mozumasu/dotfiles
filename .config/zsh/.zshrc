#!/bin/zsh
# oh-my-zshをインストールしたパス
export ZSH="$HOME/.oh-my-zsh"

# oh-my-zshでロードするプラグインの設定
plugins=(git web-search rye)

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
zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

fzf-ssh() {
  local ssh_hosts_dir="$HOME/.ssh/conf.d/hosts"
  local selected_host=$(grep -h -E -v '^#' "$ssh_hosts_dir"/* | grep -E '^HOST ' | awk '{print $2}' | fzf --prompt="Select SSH Host> ")

  if [[ -n "$selected_host" ]]; then
    echo "Connecting to $selected_host..."
    ssh "$selected_host"
  else
    echo "No host selected."
  fi
}

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
alias zshconf="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias ls='ls -F --color=auto'
alias mul='multipass'
alias ggrks='google'
alias sshf='fzf-ssh'
abbr -S -qq ll='ls -l'
abbr -S -qq la='ls -A'
abbr -S -qq lla='ls -l -A'
abbr -S -qq v='vim'
abbr -S -qq g='git'
abbr -S -qq gst='git status'
abbr -S -qq gsw='git switch'
abbr -S -qq gbr='git branch'
abbr -S -qq gfe='git fetch'
abbr -S -qq gpl='git pull'
abbr -S -qq gad='git add'
abbr -S -qq gcm='git commit'
abbr -S -qq gmg='git merge'
abbr -S -qq gpsh='git push'
abbr -S -qq lg='lazygit'
abbr -S -qq f='open .'
abbr -S -qq relogin='exec $SHELL -l'
abbr -S -qq ap='ansible-playbook'
abbr -S -qq awsl='aws configure list'
abbr -S -qq hosts='sudo nvim /etc/hosts'
abbr -S -qq dhosts='nvim ~/.ssh/conf.d/hosts/'
abbr -S -qq proot='cd $(git rev-parse --show-toplevel)'

# zsh hook
zshaddhistory() {
    local line="${1%%$'\n'}"
    if [ $? -ne 0 ]; then
        return 1
    fi
    [[ ! "$line" =~ "^(cd|jj?|lazygit|la|ll|ls|rm|rmdir|z)($| )" ]]
}

# Laravel sail
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

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
# java
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@11/11.0.24/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include"

# TiDB
export PATH=/Users/mozumasu/.tiup/bin:$PATH

# pnpm
export PNPM_HOME="/Users/mozumasu/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# volta
autoload -Uz add-zsh-hook
function chpwd_volta_install() {
  # .node-versionが存在するかチェック
  if [[ -e ".node-version" ]]; then
    # .node-versionから内容を読み取る
    content=$(cat .node-version)
    volta install node@$content --quiet
  fi

  # .nvmrcが存在するかチェック
  if [[ -e ".nvmrc" ]]; then
    # .nvmrcから内容を読み取る
    content=$(cat .nvmrc)

    case $content in
    # lts/argonの場合
    "lts/argon")
      volta install node@4 --quiet
      ;;
    # lts/boronの場合
    "lts/boron")
      volta install node@6 --quiet
      ;;
    # lts/carbonの場合
    "lts/carbon")
      volta install node@8 --quiet
      ;;
    # lts/dubniumの場合
    "lts/dubnium")
      volta install node@10 --quiet
      ;;
    # lts/erbiumの場合
    "lts/erbium")
      volta install node@12 --quiet
      ;;
    # lts/fermiumの場合
    "lts/fermium")
      volta install node@14 --quiet
      ;;
    # lts/galliumの場合
    "lts/gallium")
      volta install node@16 --quiet
      ;;
    # lts/hydrogenの場合
    "lts/hydrogen")
      volta install node@18 --quiet
      ;;
    # lts/*の場合
    "lts/*")
      volta install node@lts --quiet
      ;;
    # latest,current,node,*の場合
    "latest" | "current" | "node" | "*")
      volta install node@latest --quiet
      ;;
    # それ以外の場合
    *)
      volta install node@$content --quiet
      ;;
    esac
  fi
}
add-zsh-hook chpwd chpwd_volta_install

# ghq
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/README.*")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^g' ghq-fzf

export PATH=$PATH:$HOME/go/bin

# Move to the open finder directory
cdf() {
  target=`osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)'`
  if [ "$target" != "" ]; then
    cd "$target"; pwd
  else
    echo 'No Finder window found' >&2
  fi
}
# mise
if type mise &>/dev/null; then
  eval "$(mise activate zsh)"
  eval "$(mise activate --shims)"
fi

# extend which
function wch() {
  result=`type $1`

  if [ "`echo $result | grep 'not found'`" ]; then
    echo 'not found'
  elif [ "`echo $result | grep 'shell builtin'`" ]; then
    echo 'shell built-in'
  else
    found=`echo $result | rev | cut -d ' ' -f 1 | rev`
    dir=`dirname $found`
    if [ $# = 1 ]; then
      echo $found
    elif [ $2 = 'ls' ]; then
      ls $dir
    elif [ $2 = 'dir' ]; then
      echo $dir
    elif [ $2 = 'cd' ]; then
      cd $dir
    elif [ $2 = 'vi' ]; then
      if [ "`file $found | grep 'ASCII text'`" ]; then
        vi $found
      else
        echo 'not a text'
      fi
    fi
  fi
}

# Must be at the end of the file
eval "$(zoxide init zsh)"
