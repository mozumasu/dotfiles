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
    # suiko は日本語散文向けなので、記事とノートだけを対象にする。
    # SKILL.md や README のような箇条書き中心の文書では指摘がノイズになる。
    case "$FILE_PATH" in
      */zenn/articles/*|*/mozumasu/nb/*)
        LABEL=$(basename "$FILE_PATH")
        # 統計系の warn (機械的なリズム等) は書き直しが要るので止める
        ~/.config/claude/hooks/suiko-lint.sh "$FILE_PATH" tech warn "$LABEL" block || exit 2
        # 局所的な info (翻訳調・AI 定型) は執筆の手を止めずに伝える
        ~/.config/claude/hooks/suiko-lint.sh "$FILE_PATH" tech info "$LABEL" hint
        ;;
    esac
    ;;
  *.nix)
    echo "$INPUT" | ~/.config/claude/hooks/format-nix.sh
    ;;
  *.tf|*.tfvars|*.tfvars.json)
    echo "$INPUT" | python3 ~/.config/claude/hooks/terraform-post-hook.py
    ;;
esac

exit 0
