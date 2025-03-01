#!/usr/bin/env bash

set -ue

DOTFILES_DIR="$HOME/dotfiles"

SYMLINK_EXCLUDE_FILES=(
  "README.md"
  "Taskfile.yml"
  "vm"
  "images"
  "docs"
  "bin"
  ".zsh_history"
  "git-templates"
)

# Create symbolic links for dotfiles
if cd "$DOTFILES_DIR"; then
  # SYMLINK_EXCLUDE_FILES のリストを grep 用のパターンに変換
  EXCLUDE_PATTERN=$(printf "%s\n" "${SYMLINK_EXCLUDE_FILES[@]}" | sed 's|\.|\\.|g' | tr '\n' '|')
  EXCLUDE_PATTERN="${EXCLUDE_PATTERN%|}" # 末尾の | を削除

  find . -type f ! -path '*.git/*' ! -name '*.DS_Store' | cut -c 3- | grep -v -E "$EXCLUDE_PATTERN" | while IFS= read -r file; do

    mkdir -p "$HOME/$(dirname "$file")"

    if [ -L "$HOME/$file" ]; then
      # If an existing symbolic link exists, overwrite it, and when registering a link, display the registered name and destination.
      ln -sfv "$DOTFILES_DIR/$file" "$HOME/$file"
    else
      # If no symbolic link exists, create the link in interactive mode
      ln -sniv "$DOTFILES_DIR/$file" "$HOME/$file"
    fi
  done
else
  command echo "$DOTFILES_DIR is not found." >&2
  exit 1
fi

command echo "Complete!🚀"
