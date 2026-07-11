#!/bin/bash
# PreToolUse dispatcher: コマンド内容に応じて必要なフックのみ実行する。
#
# 子フックの出力は2種類:
#   - block 判定 (permissionDecision: "deny" / decision: "block" / exit 2)
#     -> 即座に伝播して短絡終了
#   - hint (hookSpecificOutput.additionalContext のみ)
#     -> 後続のフックも回したいので集約し、最後にまとめて出す

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[ -z "$COMMAND" ] && exit 0

HINTS=()

# 子フックを実行する。
#   - exit 2: そのまま exit 2 で伝播
#   - JSON で permissionDecision: deny / decision: block を返した: そのまま echo して exit 0
#   - JSON で additionalContext だけを返した: HINTS に積んで継続
#   - それ以外 (空 / 非 JSON): 何もしない
run_check() {
  local output exit_code
  output=$(echo "$INPUT" | "$@" 2>&1)
  exit_code=$?

  if [ "$exit_code" -eq 2 ]; then
    echo "$output"
    exit 2
  fi

  [ -z "$output" ] && return 0

  # block 判定なら即座に短絡
  if echo "$output" | jq -e '
    .hookSpecificOutput.permissionDecision == "deny"
    or .decision == "block"
  ' >/dev/null 2>&1; then
    echo "$output"
    exit 0
  fi

  # hint (additionalContext) なら集約
  local ctx
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)
  if [ -n "$ctx" ]; then
    HINTS+=("$ctx")
  fi
}

# git コマンドのみ git push チェックを実行
# コマンドとしての git にのみマッチ（ファイルパス中の git* は除外）
if echo "$COMMAND" | grep -qE '(^|[;&|] *)git\b'; then
  run_check python3 ~/.config/claude/hooks/prevent-git-push.py
  # git commit 時はスタイルを検出してヒント注入、さらに subject/body を検証して逸脱を block
  if echo "$COMMAND" | grep -qE 'git\s+commit\b'; then
    run_check ~/.config/claude/hooks/detect-commit-style.sh
    run_check python3 ~/.config/claude/hooks/validate-commit-style.py
  fi
fi

# terraform / terragrunt コマンドのみ apply チェックと Docker ルーティングを実行
# コマンドとしての terraform にのみマッチ（ファイルパス中の terraform.tf 等は除外）
if echo "$COMMAND" | grep -qE '(^|[;&|] *)(terraform|terragrunt)\b'; then
  run_check python3 ~/.config/claude/hooks/terraform-hook.py
fi

# & / nohup / setsid / disown を含むコマンドのみバックグラウンド化チェックを実行
if echo "$COMMAND" | grep -qE '&|(^|[;|(] *)(nohup|setsid|disown)\b'; then
  run_check ~/.config/claude/hooks/prevent-shell-background.sh
fi

# 集約された hint をまとめて 1 件の hookSpecificOutput として出力
if [ "${#HINTS[@]}" -gt 0 ]; then
  joined=$(printf '%s\n\n' "${HINTS[@]}")
  jq -n --arg ctx "$joined" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
fi

exit 0
