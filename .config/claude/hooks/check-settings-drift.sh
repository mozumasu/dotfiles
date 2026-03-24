#!/usr/bin/env bash
# Stop hook: settings.json が Nix 管理の状態から変更されていたら警告する
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"
CURRENT="$CLAUDE_DIR/settings.json"
REFERENCE="$CLAUDE_DIR/.settings.json.nix-managed"
NOTIFIED_FLAG="/tmp/claude-settings-drift-notified"

# 参照ファイルがなければスキップ（Nix 管理外の環境）
[ -f "$REFERENCE" ] || exit 0
[ -f "$CURRENT" ] || exit 0

# JSON を正規化して比較（キー順序の違いを無視）
if command -v jq >/dev/null 2>&1; then
  CURRENT_NORMALIZED=$(jq -S . "$CURRENT" 2>/dev/null || cat "$CURRENT")
  REFERENCE_NORMALIZED=$(jq -S . "$REFERENCE" 2>/dev/null || cat "$REFERENCE")
else
  CURRENT_NORMALIZED=$(cat "$CURRENT")
  REFERENCE_NORMALIZED=$(cat "$REFERENCE")
fi

if [ "$CURRENT_NORMALIZED" != "$REFERENCE_NORMALIZED" ]; then
  if [ -f "$NOTIFIED_FLAG" ]; then
    # 2回目以降: ユーザー通知のみ（block しない）
    echo '{"systemMessage": "⚠️ settings.json の Nix ドリフトが未解決です。darwin-rebuild switch を実行してください。"}'
  else
    # 初回: Claude に block + reason で修正指示
    touch "$NOTIFIED_FLAG"
    cat <<'HOOKEOF'
{
  "decision": "block",
  "reason": "settings.json が Nix 管理の状態から変更されています。darwin-rebuild switch で上書きされるため、変更内容を claude-code.nix または sops-nix に反映してください。差分を確認するには: diff <(jq -S . ~/.config/claude/settings.json) <(jq -S . ~/.config/claude/.settings.json.nix-managed)",
  "systemMessage": "⚠️ settings.json の変更を検出 - Nix 設定への反映が必要です"
}
HOOKEOF
  fi
else
  # ドリフトが解消されたらフラグを削除
  rm -f "$NOTIFIED_FLAG"
fi
