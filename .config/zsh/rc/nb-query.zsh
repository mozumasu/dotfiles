#!/usr/bin/env zsh

# nb query and select function
nbq() {
  if [ -z "$1" ]; then
    echo "Usage: nbq <search query>"
    return 1
  fi

  local query="$*"
  local results=$(nb q "$query" --no-color 2>/dev/null | grep -E '^\[[0-9]+\]')
  
  if [ -z "$results" ]; then
    echo "No results found for: $query"
    return 1
  fi

  # Use fzf to select from results
  local selected=$(echo "$results" | fzf --ansi --preview "echo {} | sed -E 's/^\\[([0-9]+)\\].*/\\1/' | xargs nb show" --preview-window=right:60%:wrap)
  
  if [ -n "$selected" ]; then
    local note_id=$(echo "$selected" | sed -E 's/^\[([0-9]+)\].*/\1/')
    nb edit "$note_id"
  fi
}

# Alternative using zeno completion
nb-query-select() {
  local query="$1"
  if [ -z "$query" ]; then
    echo "Usage: nb-query-select <search query>"
    return 1
  fi
  
  nb q "$query" --no-color | grep -E '^\[[0-9]+\]'
}