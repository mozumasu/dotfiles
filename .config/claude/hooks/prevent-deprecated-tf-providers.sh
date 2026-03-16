#!/bin/bash
# Terraform の非推奨プロバイダー使用をブロック

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

# hashicorp/template は darwin_arm64 非対応で非推奨
if echo "$CONTENT" | grep -qE 'source\s*=\s*"hashicorp/template"'; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "hashicorp/template は非推奨で darwin_arm64 非対応。代わりに templatefile() 組み込み関数を使用してください。"
  }
}
EOF
fi
