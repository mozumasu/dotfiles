# SSH wrapper for WezTerm tab display
# This function wraps ssh command to set OSC sequence for WezTerm

function ssh() {
  local host=""
  local args=()
  
  # Parse arguments to find hostname
  for arg in "$@"; do
    if [[ ! "$arg" =~ ^- ]]; then
      # This is likely the hostname
      host="$arg"
      break
    fi
    args+=("$arg")
  done
  
  if [[ -n "$host" ]]; then
    # Remove __ prefix if present
    local display_host="${host#__}"
    
    # Set WezTerm user var with OSC sequence
    printf "\033]1337;SetUserVar=%s=%s\007" "ssh_host" "$(echo -n "$display_host" | base64)"
    
    # Execute original ssh (capture exit status)
    command ssh "$@"
    local ssh_exit_status=$?
    
    # Always clear the user var after SSH exits (with empty base64 encoded string)
    printf "\033]1337;SetUserVar=%s=%s\007" "ssh_host" "$(echo -n '' | base64)"
    
    # Force update by sending another sequence
    printf "\033]0;%s\007" "$(basename "$(pwd)")"
    
    return $ssh_exit_status
  else
    # No host found, just run ssh normally
    command ssh "$@"
  fi
}