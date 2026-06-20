#!/usr/bin/env bash
# Stop hook: settings.json が Nix 管理の状態から変更されていたら通知する
# 実際の修正は同じ Stop イベント内の agent hook が担当
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"
CURRENT="$CLAUDE_DIR/settings.json"
REFERENCE="$CLAUDE_DIR/.settings.json.nix-managed"

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
  echo '{"systemMessage": "⚠️ settings.json の Nix ドリフトを検出 - agent hook が自動修正を試みます"}'
fi
