
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

get_workspaces_info() {
    # Get private IP of WorkSpaces
    local workspaces
    workspaces=$(aws workspaces describe-workspaces \
        --query "Workspaces[*].[WorkspaceId, UserName, IpAddress, DirectoryId]" \
        --output text)

    # Output header
    echo -e "WorkspaceId\tUserName\tPublicIpAddress\tDirectoryId" | column -t

    # Find ENI for each WorkSpace
     while read -r workspace_id username private_ip directory_id; do
        local public_ip="None"
        if [ "$private_ip" != "None" ]; then
            # Get public IP by ENI
            public_ip=$(aws ec2 describe-network-interfaces \
                --filters "Name=private-ip-address,Values=$private_ip" \
                --query "NetworkInterfaces[0].Association.PublicIp" \
                --output text)
        fi

        echo -e "$workspace_id\t$username\t$public_ip\t$directory_id" | column -t
    done <<< "$workspaces"
}

get_aws_service_ip() {
    # Get AWS IP ranges
    local data
    data=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json)

    # Get the service list and select with fzf.
    local selected_service
    selected_service=$(echo "$data" | jq -r '.prefixes[] | select(.region=="ap-northeast-1") | .service' | sort -u | fzf --prompt="Select AWS Service: ")

    # Quit if no service is selected.
    if [[ -z "$selected_service" ]]; then
        echo "No service selected."
        return 1
    fi

    # Displays IP ranges for selected services.
    echo "Selected Service: $selected_service"
    echo "IP Ranges for $selected_service in ap-northeast-1:"
    echo "$data" | jq -r ".prefixes[] | select(.region==\"ap-northeast-1\" and .service==\"$selected_service\") | .ip_prefix"
}

check_iam_policy() {
    # Get IAM role
    local iam_arn
    iam_arn=$(aws sts get-caller-identity --query "Arn" --output text)

    if [[ -z "$iam_arn" ]]; then
        echo "IAM role ARN could not be obtained"
        return 1
    fi

    # Extract role name from ARN
    local iam_role
    iam_role=$(echo "$iam_arn" | awk -F'/' '{print $(NF-1)}')

    if [[ -z "$iam_role" ]]; then
        echo "Failed to extract IAM role name from ARN."
        return 1
    fi

    echo "Using IAM Role: $iam_role"

    # Get the policy attached to the IAM role
    local policies
    policies=$(aws iam list-attached-role-policies --role-name "$iam_role" --query "AttachedPolicies[].{Name:PolicyName,Arn:PolicyArn}" --output json)

    if [[ -z "$policies" ]]; then
        echo "No policies found for role: $iam_role"
        return 1
    fi

    # Use fzf to select a policy
    local selected_policy
    selected_policy=$(echo "$policies" | jq -r '.[] | "\(.Name)\t\(.Arn)"' | fzf --prompt="Select a policy: " | awk '{print $2}')

    if [[ -z "$selected_policy" ]]; then
        echo "No policy selected or invalid selection."
        return 1
    fi

    echo "Selected Policy ARN: $selected_policy"

    # Get default version of the policy
    local default_version
    default_version=$(aws iam get-policy --policy-arn "$selected_policy" --query "Policy.DefaultVersionId" --output text)

    if [[ -z "$default_version" ]]; then
        echo "Failed to get default version for the selected policy."
        return 1
    fi

    # Get the policy document
    local policy_document
    policy_document=$(aws iam get-policy-version --policy-arn "$selected_policy" --version-id "$default_version" --query "PolicyVersion.Document" --output json)

    if [[ -z "$policy_document" ]]; then
        echo "Failed to fetch policy document."
        return 1
    fi

    echo "Policy Document:"
    echo "$policy_document" | jq .
}

sync_ssm_document() {
  local local_file="$1"
  local region="${2:-ap-northeast-1}" # default region
  local temp_aws_file="/tmp/ssm_document.yml"

  if [[ -z "$local_file" ]]; then
    echo "Usage: sync_ssm_document <local_file> [region]"
    return 1
  fi

  if [[ ! -f "$local_file" ]]; then
    echo "Error: Local file '$local_file' not found."
    return 1
  fi

  # 自分が作成したSSMドキュメント一覧を取得してfzfで選択
  local document_name
  document_name=$(aws ssm list-documents \
    --region "$region" \
    --filters Key=Owner,Values=Self \
    --query "DocumentIdentifiers[].Name" \
    --output json | jq -r '.[]' | fzf --prompt="Select SSM Document: ")

  if [[ -z "$document_name" ]]; then
    echo "No SSM Document selected. Exiting."
    return 1
  fi

  echo "Selected SSM Document: $document_name"

  # 確認プロンプト
  echo "Are you sure you want to update the SSM Document '$document_name' with '$local_file'? (y/n)"
  read -r confirmation
  if [[ "$confirmation" != "y" ]]; then
    echo "Update canceled."
    return 0
  fi

  # AWS上のドキュメントを取得
  aws ssm get-document \
    --name "$document_name" \
    --region "$region" \
    --query "Content" \
    --output text > "$temp_aws_file" 2>/dev/null

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to retrieve content for SSM Document '$document_name'."
    return 1
  fi

  # ローカルファイルとAWSドキュメントを比較
  if diff "$local_file" "$temp_aws_file" > /dev/null; then
    echo "No changes detected. SSM Document is up to date."
  else
    echo "Changes detected. Updating SSM Document..."
    # 最新バージョン番号を取得
    local latest_version
    latest_version=$(aws ssm list-document-versions \
      --name "$document_name" \
      --region "$region" \
      --query "DocumentVersions[0].DocumentVersion" \
      --output text)

    # ドキュメントを更新
    if aws ssm update-document \
      --name "$document_name" \
      --content file://"$local_file" \
      --document-version "$latest_version" \
      --region "$region"; then

      # バージョン番号を整数として扱い、1を加算
      latest_version=$((latest_version + 1))

      echo "SSM Document '$document_name' updated successfully to version $latest_version."
    else
      echo "SSM Document update failed."
    fi
    echo "Updating default version to $latest_version..."
    # デフォルトバージョンを最新に更新
    aws ssm update-document-default-version \
      --name "$document_name" \
      --document-version "$latest_version" \
      --region "$region"
  fi

  # 一時ファイルを削除
  rm -f "$temp_aws_file"
}

view_ssm_document() {
  local region="${1:-ap-northeast-1}" # default region
  local temp_aws_file="/tmp/ssm_document_content.yml"

  # Get the list of ssm documents you created and select them with fzf.
  local document_name
  document_name=$(aws ssm list-documents \
    --region "$region" \
    --filters Key=Owner,Values=Self \
    --query "DocumentIdentifiers[].Name" \
    --output json | jq -r '.[]' | fzf --prompt="Select SSM Document to view: ")

  if [[ -z "$document_name" ]]; then
    echo "No SSM Document selected. Exiting."
    return 1
  fi

  echo "Selected SSM Document: $document_name"

  # Retrieves the contents of the selected document.
  aws ssm get-document \
    --name "$document_name" \
    --region "$region" \
    --query "Content" \
    --output text > "$temp_aws_file" 2>/dev/null

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to retrieve content for SSM Document '$document_name'."
    return 1
  fi

  # Display the contents of the retrieved document.
  echo "Content of SSM Document '$document_name':"
  bat "$temp_aws_file"

  rm -f "$temp_aws_file"
}

create_ssm_document() {
  local content_file="$1"   # 第1引数でファイルパスを受け取る
  local document_name="$2" # 第2引数でドキュメント名を受け取る
  local region="${3:-ap-northeast-1}" # 第3引数でリージョンを指定（デフォルトは ap-northeast-1）

  # 引数が指定されていない場合はエラーメッセージを表示して終了
  if [[ -z "$content_file" ]]; then
    echo "Usage: create_ssm_document <content_file> [document_name] [region]"
    return 1
  fi

  # 引数のファイルが存在しない場合
  if [[ ! -f "$content_file" ]]; then
    echo "Error: File '$content_file' not found."
    return 1
  fi

  # ドキュメント名が指定されていない場合、プロンプトで入力を求める
  if [[ -z "$document_name" ]]; then
    echo "Enter the name for the SSM Document:"
    read -r document_name
  fi

  # ドキュメント名が空の場合はエラーを表示して終了
  if [[ -z "$document_name" ]]; then
    echo "Error: Document name cannot be empty."
    return 1
  fi

  # fzfでドキュメントタイプを選択
  local document_type
  document_type=$(echo -e "Command\nAutomation\nPolicy\nSession\nPackage" | fzf --prompt="Select Document Type: ")

  if [[ -z "$document_type" ]]; then
    echo "Error: No document type selected."
    return 1
  fi

  # fzfでファイル形式を選択
  local file_format
  file_format=$(echo -e "YAML\nJSON" | fzf --prompt="Select File Format: ")

  if [[ -z "$file_format" ]]; then
    echo "Error: No file format selected."
    return 1
  fi

  # ファイル形式に応じて content の指定を変更
  local content_option
  if [[ "$file_format" == "YAML" ]]; then
    content_option="file://$content_file"
  elif [[ "$file_format" == "JSON" ]]; then
    content_option="file://$content_file"
  else
    echo "Error: Invalid file format selected."
    return 1
  fi

  # AWS CLIコマンドを実行してSSMドキュメントを作成
  aws ssm create-document \
    --name "$document_name" \
    --document-type "$document_type" \
    --content "$content_option" \
    --region "$region"

  # 結果を表示
  if [[ $? -eq 0 ]]; then
    echo "SSM Document '$document_name' of type '$document_type' with format '$file_format' created successfully in region '$region'."
  else
    echo "Failed to create SSM Document."
  fi
}

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
