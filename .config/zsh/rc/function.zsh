
# ----------------------------------------------------
# Function
# ----------------------------------------------------

# https://rcmdnk.com/blog/2014/07/20/computer-vim/
function man {
  local p
  local m
  if [ "$PAGER" != "" ];then
    p="$PAGER"
  fi
  if [ "$MANPAGER" != "" ];then
    m="$MNNPAGER"
  fi
  unset PAGER
  unset MANPAGER
  val=$(command man $* 2>&1)
  ret=$?
  if [ $ret -eq 0 ];then
    echo "$val"|col -bx|nvim -R -c 'set ft=man' -
  else
    echo "$val"
  fi
  if [ "$p" != "" ];then
    export PAGER="$p"
  fi
  if [ "$m" != "" ];then
    export MANPAGER="$m"
  fi
  return $ret
}

# Create .gitignore file by gibo
create_gitignore() {
    local input_file="$1"

    # If the input is empty, set .gitignore to the default value.
    if [[ -z "$input_file" ]]; then
        input_file=".gitignore"
    fi

    # Capture the selected templates from fzf
    local selected=$(gibo list | fzf \
        --multi \
        --preview "gibo dump {} | bat --style=numbers --color=always --paging=never")

    # If no selection was made, exit the function
    if [[ -z "$selected" ]]; then
        echo "No templates selected. Exiting."
        return
    fi

    # Dump the selected templates into the specified file
    echo "$selected" | xargs gibo dump >> "$input_file"

    # Display the resulting file with bat
    bat "$input_file"
}

# AWS
function set_aws_profile() {
  local selected_profile=$(aws configure list-profiles |
    grep -v "default" |
    sort |
    fzf --prompt "Select PROFILE. If press Ctrl-C, unset PROFILE. > " \
        --height 50% --layout=reverse --border --preview-window 'right:50%' \
        --preview "grep {} -A5 ~/.aws/config")

  # Cancel settings if no profile is selected
  if [ -z "$selected_profile" ]; then
    echo "Unset aws profile!"
    unset AWS_PROFILE
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    return
  fi

  # settings for the selected profile.
  echo "Set the environment variable 'AWS_PROFILE' to '${selected_profile}'!"
  export AWS_PROFILE="$selected_profile"
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY

  # Check your sso session and log in again if it has expired.
  local AWS_SSO_SESSION_NAME="mozumasu"

  check_sso_session=$(aws sts get-caller-identity 2>&1)
  if [[ "$check_sso_session" == *"Token has expired"* ]]; then
    echo -e "\n----------------------------\nYour Session has expired! Please login...\n----------------------------\n"
    aws sso login --sso-session "${AWS_SSO_SESSION_NAME}"
    aws sts get-caller-identity
  else
    echo ${check_sso_session}
  fi
}

get_workspaces_ips() {
    # Get private IP of WorkSpaces
    local workspaces
    workspaces=$(aws workspaces describe-workspaces \
        --query "Workspaces[*].[WorkspaceId, UserName, IpAddress]" \
        --output text)

    # Output header
    echo -e "WorkspaceId\tUserName\tPublicIpAddress" | column -t

    # Find ENI for each WorkSpace
     while read -r workspace_id username private_ip; do
        local public_ip="None"
        if [ "$private_ip" != "None" ]; then
            # Get public IP by ENI
            public_ip=$(aws ec2 describe-network-interfaces \
                --filters "Name=private-ip-address,Values=$private_ip" \
                --query "NetworkInterfaces[0].Association.PublicIp" \
                --output text)
        fi

        echo -e "$workspace_id\t$username\t$public_ip" | column -t
    done <<< "$workspaces"
}
alias wsip='get_workspaces_ips'

# Ansible init
ansible_init() {
  mkdir -p group_vars/{development,production}/server_account group_vars/all/{secret,server_account} playbooks roles/{account,os_settings,pre_setup}/{defaults,tasks}
}

ansible_create_role(){
  mkdir -p roles/$1/{tasks,handlers,templates,files,vars,defaults,meta}
}


# zsh hook
zshaddhistory() {
    local line="${1%%$'\n'}"
    if [ $? -ne 0 ]; then
        return 1
    fi
    [[ ! "$line" =~ "^(cd|jj?|lazygit|la|ll|ls|rm|rmdir|z)($| )" ]]
}

# wezterm
# OSC 133
_prompt_executing=""
function __prompt_precmd() {
    local ret="$?"
    if test "$_prompt_executing" != "0"
    then
      _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
    fi
    if test "$_prompt_executing" != ""
    then
       printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
    fi
    printf "\033]133;A;cl=m;aid=%s\007" "$$"
    _prompt_executing=0
}
function __prompt_preexec() {
    PS1="$_PROMPT_SAVE_PS1"
    PS2="$_PROMPT_SAVE_PS2"
    printf "\033]133;C;\007"
    _prompt_executing=1
}
preexec_functions+=(__prompt_preexec)
precmd_functions+=(__prompt_precmd)

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

# fzf
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

# ----------------------------------------------------
# for Mac
# ----------------------------------------------------

# vpnutil ( for Mac )
# https://github.com/Timac/VPNStatus
check_vpn_status() {
  # Extract the output of vpnutil list as json.
  vpn_data=$(vpnutil list)

  # Extract connected vpn.
  connected_vpns=$(echo "$vpn_data" | jq -r '.VPNs[] | select(.status == "Connected") | "\(.name) (\(.status))"')

  if [[ -z "$connected_vpns" ]]; then
    echo "No Connected"
  else
    echo "Connected VPN:"
    echo "$connected_vpns"
  fi
}

vpn_connect_with_fzf() {
  # Extract the output of vpnutil list as json.
  vpn_data=$(vpnutil list)

  # Get the name and status of the VPN and select it with fzf.
  selected_vpn=$(echo "$vpn_data" | jq -r '.VPNs[] | "\(.name) (\(.status))"' | fzf --prompt="choose a vpn: ")

  # If there is no selected VPN, exit
  if [[ -z "$selected_vpn" ]]; then
    echo "VPN selection canceled."
    return
  fi

  # Extract the vpn name
  vpn_name=$(echo "$selected_vpn" | sed 's/ (.*)//')

  # Connection place
  echo "connection: $vpn_name"
  vpnutil start "$vpn_name"
}

vpn_disconnect_if_connected() {
  # Extract the output of vpnutil list as json.
  vpn_data=$(vpnutil list)

  # Extract connected VPN
  connected_vpns=$(echo "$vpn_data" | jq -r '.VPNs[] | select(.status == "Connected") | .name')

  if [[ -z "$connected_vpns" ]]; then
    echo "No vpn connected."
  else
    echo "Disconnect the following VPN connections:"
    echo "$connected_vpns"
    
    # Turn off each connected VPN.
    for vpn in $connected_vpns; do
      echo "cutting: $vpn"
      vpnutil stop "$vpn"
    done
    echo "Disconnected all vpn connections."
  fi
}


# Open the selected application with new window
function newapp() {
  local app=$(find /Applications -name "*.app" -maxdepth 1 | sed 's|/Applications/||' | fzf \
    --prompt="Select an application: " \
    --height=20% \
    --preview="echo '🍎 Application Name: {1}\n' && echo '' && mdls -name kMDItemDisplayName -name kMDItemVersion -name kMDItemKind /Applications/{1} || echo 'No metadata available'" \
    --preview-window=right:40%)

  if [[ -z "$app" ]]; then
    echo "No application selected."
    return 1
  fi

  echo "Opening $app..."
  open -n "/Applications/$app"
}
