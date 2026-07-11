#!/bin/bash
# Claude Code PostToolUse hook for formatting .nix files
# - Uses `nix fmt` if flake.nix exists in parent directories
# - Falls back to `nixfmt` otherwise

# Read file path from stdin (JSON from Claude Code)
file=$(jq -r '.tool_input.file_path | select(endswith(".nix"))')

# Exit if not a .nix file
[ -z "$file" ] && exit 0

# Find flake.nix in parent directories
dir=$(dirname "$file")
found=0

while [ "$dir" != "/" ]; do
  if [ -f "$dir/flake.nix" ]; then
    (cd "$dir" && nix fmt "$file" 2>/dev/null)
    found=1
    break
  fi
  dir=$(dirname "$dir")
done

# Fallback to nixfmt if no flake.nix found
if [ "$found" = 0 ]; then
  nixfmt "$file" 2>/dev/null
fi
