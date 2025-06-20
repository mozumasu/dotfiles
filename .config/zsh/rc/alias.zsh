
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


# aws
alias qc="q chat --model claude-4-sonnet --trust-tools=mcp,fs_read,fs_write"
alias awsp='set_aws_profile'
alias awsvl='aws_vault_login'
alias awsv='aws-vault'
alias ec2ls='(echo -e "InstanceId\tName\tPublicIpAddress" && aws ec2 describe-instances --query '\''Reservations[*].Instances[*].[InstanceId, Tags[?Key==`Name`].Value | [0], PublicIpAddress]'\'' --output text) | column -t'
alias wsls='get_workspaces_info'
alias awsip='get_aws_service_ip'
alias iam='check_iam_policy'
alias ssmdv='view_ssm_document'
alias ssmdsync='sync_ssm_document'
alias awsconfig='v ~/.aws/config'
alias awscredentials='v ~/.aws/credentials'

# SVN
alias svnbat='bat ~/dotfiles/docs/svn.md'
alias svna='svn st | grep "^?" | awk "{print $2}" | xargs svn add'
alias svnr='svn st | grep "^!" | awk "{print $2}" | xargs svn rm'

# function alias
alias sshf='fzf-ssh'
alias gi='create_gitignore'

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
alias vpns='check_vpn_status'
alias vpnc='vpn_connect_with_fzf'
alias vpnd='vpn_disconnect_if_connected'

# notification
alias beep='for i in {1..3}; do afplay /System/Library/Sounds/Submarine.aiff; done'
