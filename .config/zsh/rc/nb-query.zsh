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

  # Create preview command that shows matching lines with context
  # Export query so it's available in the preview command
  export _NBQ_QUERY="$query"
  
  # Use fzf to select from results with enhanced preview
  local selected=$(echo "$results" | fzf --ansi \
    --preview 'note_id=$(echo {} | sed -E "s/^\[([0-9]+)\].*/\1/")
               echo "=== Note [$note_id] ==="
               echo ""
               nb show "$note_id" | head -5
               echo ""
               echo "=== Matching lines ==="
               echo ""
               nb show "$note_id" | grep -i --color=always -C 2 "$_NBQ_QUERY" | head -30' \
    --preview-window=right:60%:wrap \
    --header "Search: $query")
  
  # Clean up exported variable
  unset _NBQ_QUERY
  
  if [ -n "$selected" ]; then
    local note_id=$(echo "$selected" | sed -E 's/^\[([0-9]+)\].*/\1/')
    nb edit "$note_id"
  fi
}

# Enhanced version with ripgrep for better highlighting
nbqr() {
  if [ -z "$1" ]; then
    echo "Usage: nbqr <search query>"
    return 1
  fi

  local query="$*"
  local results=$(nb q "$query" --no-color 2>/dev/null | grep -E '^\[[0-9]+\]')
  
  if [ -z "$results" ]; then
    echo "No results found for: $query"
    return 1
  fi

  # Export query for preview command
  export _NBQ_QUERY="$query"
  
  # Use fzf with ripgrep for better highlighting if available
  local selected=$(echo "$results" | fzf --ansi \
    --preview 'note_id=$(echo {} | sed -E "s/^\[([0-9]+)\].*/\1/")
               note_path=$(nb show "$note_id" --path 2>/dev/null)
               if [ -n "$note_path" ]; then
                 echo "=== Note [$note_id]: $(basename "$note_path") ==="
                 echo ""
                 # Show first few lines
                 head -3 "$note_path" 2>/dev/null
                 echo ""
                 echo "=== Matching content ==="
                 echo ""
                 # Use ripgrep if available for better highlighting
                 if command -v rg >/dev/null 2>&1; then
                   rg -i --color=always -C 3 --max-count=5 "$_NBQ_QUERY" "$note_path" 2>/dev/null || \
                   grep -i --color=always -C 2 "$_NBQ_QUERY" "$note_path" 2>/dev/null | head -30
                 else
                   grep -i --color=always -C 2 "$_NBQ_QUERY" "$note_path" 2>/dev/null | head -30
                 fi
               else
                 nb show "$note_id" | grep -i --color=always -C 2 "$_NBQ_QUERY" | head -30
               fi' \
    --preview-window=right:65%:wrap \
    --header "Search: $query" \
    --bind "ctrl-y:execute-silent(echo {} | sed -E 's/^\[([0-9]+)\].*/\1/' | xargs nb show | pbcopy)+abort" \
    --header-lines=0)
  
  unset _NBQ_QUERY
  
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