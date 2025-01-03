
# ----------------------------------------------------
# Alias
# ----------------------------------------------------

# common
alias v='nvim'
alias ls='ls -F --color=auto'
abbr -S -qq -='cd -'
abbr -S -qq ll='ls -l'
abbr -S -qq la='ls -A'
abbr -S -qq lla='ls -l -A'
abbr -S -qq relogin='exec $SHELL -l'
abbr -S -qq myip='curl ifconfig.me'
abbr -S -qq dhosts='nvim ~/.ssh/conf.d/hosts/'
abbr -S -qq hosts='sudo nvim /etc/hosts'

# git
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
abbr -S -qq proot='cd $(git rev-parse --show-toplevel)'

# configure file
alias zshconf="nvim ~/.zshrc"

# zenn
alias zenn='nvim ~/src/private/zenn'

# infra
alias awsv='aws-vault'
alias mul='multipass'
abbr -S -qq ap='ansible-playbook'
abbr -S -qq awsl='aws configure list'

# SVN
alias svnbat='bat ~/dotfiles/docs/svn.md'
alias svna='svn st | grep "^?" | awk "{print $2}" | xargs svn add'
alias svnr='svn st | grep "^!" | awk "{print $2}" | xargs svn rm'

# function alias
alias sshf='fzf-ssh'
alias gi='create_gitignore'

# ----------------------------------------------------
# for Mac
# ----------------------------------------------------
abbr -S -qq f='open .'

# vpnutil
abbr -S -qq vpn='vpnutil'
alias vpns='check_vpn_status'
alias vpnc='vpn_connect_with_fzf'
alias vpnd='vpn_disconnect_if_connected'
