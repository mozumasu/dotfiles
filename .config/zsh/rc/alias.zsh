
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

# rm
[[ $(command -v gomi) ]] && alias gm='gomi'

# ESC H
alias run-help >/dev/null 2>&1 && unalias run-help
autoload -Uz run-help run-help-git run-help-openssl run-help-sudo

# aws
alias awsp='set-aws-profile'
alias awsvl='aws-vault-login'
alias ec2ls='(echo -e "InstanceId\tName\tPublicIpAddress" && aws ec2 describe-instances --query '\''Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]'\'' --output text) | column -t'
alias wsls='get-workspaces-info'
alias awsip='get-aws-service-ip'
alias iam='check-iam-policy'
alias ssmdv='view-ssm-document'
alias ssmdsync='sync-ssm-document'
alias awsconfig='v ~/.aws/config'
alias awscredentials='v ~/.aws/credentials'

# function alias
alias sshf='fzf-ssh'
alias gi='create-gitignore'

# Claude
alias claudeconfig='v ~/Library/Application\ Support/Claude/claude_desktop_config.json'

# ----------------------------------------------------
# Hash
# ----------------------------------------------------
hash -d xdata=$XDG_DATA_HOME
hash -d nvim=$XDG_DATA_HOME/nvim
hash -d nvimplugins=$XDG_DATA_HOME/nvim/lua

# ----------------------------------------------------
# for Mac
# ----------------------------------------------------
# karabiner
alias killkara='sudo killall karabiner_grabber'

# vpnutil
alias vpns='check-vpn-status'
alias vpnc='vpn-connect-with-fzf'
alias vpnd='vpn-disconnect-if-connected'

# notification
alias beep='for i in {1..3}; do afplay /System/Library/Sounds/Submarine.aiff; done'
