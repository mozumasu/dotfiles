#!/bin/bash
# ~/.claude/ 配下のファイル編集を検出し、正しい編集先を案内する
# - settings.json → Nix管理 (claude-code.nix の publicSettings)
# - その他 → dotfiles側の対応パス

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

# file_path が空ならスキップ
[ -z "$FILE_PATH" ] && exit 0

# ~ を展開
EXPANDED=$(eval echo "$FILE_PATH")

# ~/.claude/ 配下かチェック（~/.config/claude/ のシンボリックリンク先も含む）
REAL_PATH=$(realpath "$EXPANDED" 2>/dev/null || echo "$EXPANDED")
DOTFILES_DIR=$(realpath "$HOME/dotfiles/.config/claude" 2>/dev/null)
NIX_CLAUDE_CODE="$HOME/dotfiles/.config/nix/home-manager/claude-code.nix"

# 既に dotfiles 側を編集している場合はスキップ
[[ "$REAL_PATH" == "$DOTFILES_DIR"/* ]] && exit 0

# claude-code.nix を編集している場合はスキップ
NIX_REAL_PATH=$(realpath "$NIX_CLAUDE_CODE" 2>/dev/null)
[[ "$REAL_PATH" == "$NIX_REAL_PATH" ]] && exit 0

# ~/.claude/ 配下のファイルをブロック
if [[ "$EXPANDED" == "$HOME/.claude/"* ]] || [[ "$EXPANDED" == "$HOME/.config/claude/"* ]]; then
  # dotfiles側の対応パスを算出
  if [[ "$EXPANDED" == "$HOME/.claude/"* ]]; then
    RELATIVE="${EXPANDED#$HOME/.claude/}"
  else
    RELATIVE="${EXPANDED#$HOME/.config/claude/}"
  fi

  # settings.json は Nix 管理なので claude-code.nix に誘導
  if [[ "$RELATIVE" == "settings.json" ]]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "settings.json は Nix (darwin-rebuild) で生成されるファイルです。直接編集しても次回の darwin-rebuild switch で上書きされます。代わりに $NIX_CLAUDE_CODE の publicSettings を編集してください。"
  }
}
EOF
  else
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "このファイルはシンボリックリンクで管理されています。直接 ~/.claude/ を編集せず、dotfiles側を編集してください: $HOME/dotfiles/.config/claude/$RELATIVE"
  }
}
EOF
  fi
fi
