#!/bin/bash
# PostToolUse dispatcher: Write|Edit|MultiEdit 後にファイルタイプ別フォーマッターを実行

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.js|*.ts|*.jsx|*.tsx)
    # グローバル prettier → プロジェクトローカル prettier の順で試行
    if command -v prettier >/dev/null 2>&1; then
      prettier --write "$FILE_PATH" 2>/dev/null || true
    elif command -v npx >/dev/null 2>&1; then
      # --no-install: 未インストール時にネットワーク経由でインストールしない
      npx --no-install prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
  *.md)
    # rumdl は「ファイル側の最近傍 .rumdl.toml を読み、exclude はプロセス cwd 基準で照合する」。
    # セッション cwd のままだと別リポジトリのファイルで exclude が効かないため、
    # ファイルの属するリポジトリのルートへ cd してから実行する
    if command -v rumdl >/dev/null 2>&1; then
      REPO_ROOT=$(git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null)
      if [ -n "$REPO_ROOT" ]; then
        (cd "$REPO_ROOT" && rumdl fmt "$FILE_PATH")
      else
        rumdl fmt "$FILE_PATH"
      fi
    fi
    ;;
  *.nix)
    echo "$INPUT" | ~/.config/claude/hooks/format-nix.sh
    ;;
  *.tf|*.tfvars|*.tfvars.json)
    echo "$INPUT" | python3 ~/.config/claude/hooks/terraform-post-hook.py
    ;;
esac

exit 0
