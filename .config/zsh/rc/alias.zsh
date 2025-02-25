
# ----------------------------------------------------
# Alias
# ----------------------------------------------------

# common
alias v='nvim'
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
else
  alias ls='ls -F --color=auto'
fi
alias ...='../../'
alias ....='../../../'
alias .....='../../../../'
alias -g G='| grep'
abbr -S -qq -='cd -'
abbr -S -qq ll='ls -l'
abbr -S -qq la='ls -A'
abbr -S -qq lla='ls -l -A'
abbr -S -qq r='exec $SHELL -l'
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
alias szsh="source ~/dotfiles/.config/zsh/.zshrc"

# rm
[[ $(command -v gomi) ]] && alias gm='gomi'

# zenn
alias zenn='nvim ~/src/private/zenn'

# infra
alias mul='multipass'
abbr -S -qq ap='ansible-playbook'
abbr -S -qq tf='terraform'
abbr -S -qq tfi='terraform init'
abbr -S -qq tfp='terraform plan'
abbr -S -qq tfa='terraform apply'
abbr -S -qq tfs='terraform state'
abbr -S -qq tfsl='terraform state list'

# aws
abbr -S -qq awsl='aws configure list'
abbr -S -qq awsm='aws-mfa'
alias awsp='set_aws_profile'
alias awsv='aws-vault'
alias ec2ls='(echo -e "InstanceId\tName\tPublicIpAddress" && aws ec2 describe-instances --query '\''Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]'\'' --output text) | column -t'
alias wsls='get_workspaces_info'
alias awsip='get_aws_service_ip'
alias iam='check_iam_policy'
alias ssmdv='view_ssm_document'
alias ssmdsync='sync_ssm_document'
alias awsconfig='v ~/.aws/config'
alias ascredentials='v ~/.aws/credentials'

# SVN
alias svnbat='bat ~/dotfiles/docs/svn.md'
alias svna='svn st | grep "^?" | awk "{print $2}" | xargs svn add'
alias svnr='svn st | grep "^!" | awk "{print $2}" | xargs svn rm'

# function alias
alias sshf='fzf-ssh'
alias gi='create_gitignore'

# python
[[ $(command -v python3) ]] && abbr -S -qq py='python3'
[[ $(command -v uv) ]] && abbr -S -qq upy='uv run python'

# Laravel sail
alias sail='[ -f sail ] && bash sail || bash vendor/bin/sail'

# ----------------------------------------------------
# Hash
# ----------------------------------------------------
hash -d xdata=$XDG_DATA_HOME
hash -d nvim=$XDG_DATA_HOME/nvim
hash -d nvimplugins=$XDG_DATA_HOME/nvim/lua

# ----------------------------------------------------
# for Mac
# ----------------------------------------------------
abbr -S -qq f='open .'

# karabiner
alias killkara='sudo killall karabiner_grabber'

# vpnutil
abbr -S -qq vpn='vpnutil'
alias vpns='check_vpn_status'
alias vpnc='vpn_connect_with_fzf'
alias vpnd='vpn_disconnect_if_connected'

# notification
alias beep='for i in {1..3}; do afplay /System/Library/Sounds/Submarine.aiff; done'
alias notify='terminal-notifier -message "complete"'


# ----------------------------------------------------
# for Mac
# ----------------------------------------------------
abbr -S -qq p_rm='python3 ~/src/github.com/mozumasu/python/article/rename_cleanup.py'
