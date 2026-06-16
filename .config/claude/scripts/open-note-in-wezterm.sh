#!/usr/bin/env bash
# open-note-in-wezterm.sh — 指定ファイルを新しい WezTerm タブで開く。
# save-answer.sh / save-session.sh の -o/--open から呼ばれる共有ヘルパー。
#
# Usage: open-note-in-wezterm.sh <file>
#
# ビューアは環境変数 NB_VIEWER で上書き可（例: NB_VIEWER="nvim"）。
# 未指定時は glow -> bat -> nvim -> less の順で利用可能なものを使う。
#
# 注意: 保存自体は呼び出し側で完了済み。ここで失敗しても保存は成功扱いの
#       ままにしたいので、エラーでも非ゼロ終了させず警告のみ出して返る。
set -uo pipefail

FILE="${1:-}"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "open-note: ファイルが見つかりません: ${FILE:-(空)}" >&2
  exit 0
fi

if ! command -v wezterm >/dev/null 2>&1; then
  echo "open-note: wezterm が見つからないため新規タブ表示をスキップしました" >&2
  exit 0
fi
if [ -z "${WEZTERM_PANE:-}" ]; then
  echo "open-note: WezTerm 内で実行されていないため新規タブ表示をスキップしました" >&2
  exit 0
fi

# ビューア決定（NB_VIEWER 優先。markdown 表示向けに glow を既定とする）
viewer="${NB_VIEWER:-}"
if [ -z "$viewer" ]; then
  if command -v glow >/dev/null 2>&1; then viewer="glow -p"
  elif command -v bat >/dev/null 2>&1; then viewer="bat --paging=always"
  elif command -v nvim >/dev/null 2>&1; then viewer="nvim"
  else viewer="less"; fi
fi
read -r -a vcmd <<< "$viewer"

dir="$(dirname "$FILE")"
if wezterm cli spawn --cwd "$dir" -- "${vcmd[@]}" "$FILE" >/dev/null 2>&1; then
  echo "新しい WezTerm タブで開きました（${vcmd[0]}）: $FILE"
else
  echo "open-note: 新規タブの起動に失敗しました: $FILE" >&2
fi
exit 0
