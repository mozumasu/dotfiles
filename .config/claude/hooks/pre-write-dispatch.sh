#!/bin/bash
# PreToolUse dispatcher: Write|Edit|MultiEdit 前のチェックを順に実行する。
# 子フックが出力 (deny 判定) を返したら即座に伝播して短絡終了。

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[ -z "$FILE_PATH" ] && exit 0

for check in prevent-deprecated-tf-providers.sh redirect-dotfiles.sh; do
  output=$(echo "$INPUT" | ~/.config/claude/hooks/"$check")
  exit_code=$?
  if [ "$exit_code" -eq 2 ]; then
    echo "$output"
    exit 2
  fi
  if [ -n "$output" ]; then
    echo "$output"
    exit 0
  fi
done

exit 0
