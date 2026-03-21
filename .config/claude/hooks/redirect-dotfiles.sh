#!/bin/bash
# ~/.claude/ 配下のファイル編集を検出し、~/dotfiles/.config/claude/ の編集を促す

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

# file_path が空ならスキップ
[ -z "$FILE_PATH" ] && exit 0

# ~ を展開
EXPANDED=$(eval echo "$FILE_PATH")

# ~/.claude/ 配下かチェック（~/.config/claude/ のシンボリックリンク先も含む）
REAL_PATH=$(realpath "$EXPANDED" 2>/dev/null || echo "$EXPANDED")
DOTFILES_DIR=$(realpath "$HOME/dotfiles/.config/claude" 2>/dev/null)

# 既に dotfiles 側を編集している場合はスキップ
[[ "$REAL_PATH" == "$DOTFILES_DIR"/* ]] && exit 0

# ~/.claude/ 配下のファイルをブロック
if [[ "$EXPANDED" == "$HOME/.claude/"* ]] || [[ "$EXPANDED" == "$HOME/.config/claude/"* ]]; then
  # dotfiles側の対応パスを算出
  if [[ "$EXPANDED" == "$HOME/.claude/"* ]]; then
    RELATIVE="${EXPANDED#$HOME/.claude/}"
  else
    RELATIVE="${EXPANDED#$HOME/.config/claude/}"
  fi
  DOTFILES_PATH="~/dotfiles/.config/claude/$RELATIVE"

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "このファイルはシンボリックリンクで管理されています。直接 ~/.claude/ を編集せず、dotfiles側を編集してください: $HOME/dotfiles"
  }
}
EOF
fi
