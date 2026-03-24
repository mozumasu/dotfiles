#!/bin/bash
# SNS subscriber + DAILY/WEEKLY frequency の無効な組み合わせをブロック
# AWS CE Anomaly Subscription の制約: SNS は IMMEDIATE のみ対応

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

# .tf ファイル以外はスキップ
[[ "$FILE_PATH" =~ \.tf$ ]] || exit 0

# Write: content / Edit: new_string / MultiEdit: edits[].new_string を結合
CONTENT=$(jq -r '
  (.tool_input.content? // "") +
  (.tool_input.new_string? // "") +
  ((.tool_input.edits? // []) | map(.new_string? // "") | join("\n"))
' <<<"$INPUT" 2>/dev/null)

# 編集内容に SNS subscriber が含まれるかチェック
HAS_SNS=false
if echo "$CONTENT" | grep -qE 'type\s*=\s*"SNS"'; then
  HAS_SNS=true
fi

# 編集内容に DAILY/WEEKLY frequency が含まれるかチェック
HAS_DAILY_WEEKLY=false
if echo "$CONTENT" | grep -qE 'frequency\s*=\s*"(DAILY|WEEKLY)"'; then
  HAS_DAILY_WEEKLY=true
fi

# 同一編集内で両方が存在する場合のみブロック
if [[ "$HAS_SNS" == "true" && "$HAS_DAILY_WEEKLY" == "true" ]]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "SNS subscriber は frequency=IMMEDIATE のみ対応。DAILY/WEEKLY は Email subscriber 専用です (AWS API 制約)。frequency を IMMEDIATE に変更してください。"
  }
}
EOF
  exit 0
fi

# 既存ファイル全体もチェック（Edit で片方だけ追加するケース対策）
if [[ -f "$FILE_PATH" ]]; then
  EXISTING=$(cat "$FILE_PATH" 2>/dev/null)
  MERGED="${EXISTING}
${CONTENT}"

  # aws_ce_anomaly_subscription ブロック内で SNS + DAILY/WEEKLY の組み合わせをチェック
  if echo "$MERGED" | grep -qE 'aws_ce_anomaly_subscription' && \
     echo "$MERGED" | grep -qE 'type\s*=\s*"SNS"' && \
     echo "$MERGED" | grep -qE 'frequency\s*=\s*"(DAILY|WEEKLY)"'; then
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "aws_ce_anomaly_subscription で SNS subscriber と DAILY/WEEKLY frequency の組み合わせは AWS API で禁止されています。SNS を使う場合は frequency=IMMEDIATE にしてください。"
  }
}
EOF
  fi
fi
