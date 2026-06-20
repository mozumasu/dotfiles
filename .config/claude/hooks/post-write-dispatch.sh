#!/bin/bash
# PostToolUse dispatcher: Write|Edit|MultiEdit 後にファイルタイプ別フォーマッターを実行

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.js|*.ts|*.jsx|*.tsx)
    # グローバル prettier → プロジェクトローカル prettier の順で試行
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    elif command -v npx >/dev/null 2>&1; then
      # --no-install: 未インストール時にネットワーク経由でインストールしない
      npx --no-install prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.md)
    command -v rumdl >/dev/null 2>&1 && rumdl fmt "$FILE_PATH"
    ;;
  *.nix)
    echo "$INPUT" | ~/.config/claude/scripts/format-nix.sh
    ;;
  *.tf|*.tfvars|*.tfvars.json)
    echo "$INPUT" | python3 ~/.config/claude/scripts/terraform-post-hook.py
    ;;
esac

exit 0
