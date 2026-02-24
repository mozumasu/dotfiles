#!/bin/bash
# PostToolUse dispatcher: Write|Edit|MultiEdit 後にファイルタイプ別フォーマッターを実行

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.js|*.ts)
    prettier --write "$FILE_PATH"
    ;;
  *.md)
    rumdl fmt "$FILE_PATH"
    ;;
  *.nix)
    echo "$INPUT" | ~/.config/claude/scripts/format-nix.sh
    ;;
  *.tf|*.tfvars|*.tfvars.json)
    echo "$INPUT" | python3 ~/.config/claude/scripts/terraform-post-hook.py
    ;;
esac

exit 0
