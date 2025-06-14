#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

SYMLINK_EXCLUDE_FILES=(
  "^README\.md$"
  "^Taskfile\.yml$"
  "^vm/"
  "^images/"
  "^docs/"
  "^bin/"
  "\.zsh_history$"
  "git-templates"
  "\.zcompdump.*"
  "^\.config/jgit/config$"
)

is_excluded() {
  local file="$1"
  local pattern
  for pattern in "${SYMLINK_EXCLUDE_FILES[@]}"; do
    if [[ "$file" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

create_symlink() {
  local file="$1"
  local target="$DOTFILES_DIR/$file"
  local link="$HOME/$file"
  local link_dir
  link_dir="$(dirname "$link")"

  # ディレクトリを作成
  if ! mkdir -p "$link_dir"; then
    echo "Failed to create directory: $link_dir" >&2
    return 1
  fi

  # 既存ファイルのチェック（シンボリックリンクでない場合は警告）
  if [ -f "$link" ] && [ ! -L "$link" ]; then
    echo "Warning: $link exists and is not a symlink. Skipping." >&2
    return 1
  fi

  # シンボリックリンクの作成
  if [ -L "$link" ]; then
    # 既に正しいターゲットを指している場合はスキップ
    if [ "$(readlink "$link")" = "$target" ]; then
      return 0
    fi
    ln -sfv "$target" "$link"
  else
    ln -sv "$target" "$link"
  fi
}

main() {
  if ! cd "$DOTFILES_DIR"; then
    echo "Error: $DOTFILES_DIR not found." >&2
    exit 1
  fi

  echo "Processing dotfiles in $DOTFILES_DIR..."

  # すべてのファイルを処理（macOS互換）
  while IFS= read -r file; do
    if is_excluded "$file"; then
      continue
    fi
    create_symlink "$file"
  done < <(find . -type f ! -path '*.git/*' ! -name '.DS_Store' | cut -c 3-)

  echo "Complete! 🚀"
}

main "$@"
