#!/bin/bash
# PreToolUse dispatcher: コマンド内容に応じて必要なフックのみ実行する

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[ -z "$COMMAND" ] && exit 0

# ブロック判定を伝播する共通ランナー
# - exit 2 で終了したスクリプト → そのまま exit 2 で伝播
# - {"decision":"block",...} を出力したスクリプト → そのまま stdout に流して exit 0
run_check() {
  local output exit_code
  output=$(echo "$INPUT" | "$@" 2>&1)
  exit_code=$?
  if [ "$exit_code" -eq 2 ]; then
    echo "$output"
    exit 2
  fi
  if [ -n "$output" ] && echo "$output" | jq -e '.decision == "block"' >/dev/null 2>&1; then
    echo "$output"
    exit 0
  fi
}

# git コマンドのみ git push チェックを実行
if echo "$COMMAND" | grep -qE '\bgit\b'; then
  run_check python3 ~/.config/claude/hooks/prevent-git-push.py
fi

# terraform / terragrunt コマンドのみ apply チェックと Docker ルーティングを実行
if echo "$COMMAND" | grep -qE '\b(terraform|terragrunt)\b'; then
  run_check python3 ~/.config/claude/hooks/prevent-terraform-apply.py
  run_check ~/.config/claude/scripts/terraform-runner.sh
fi

exit 0
