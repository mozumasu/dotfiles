#!/usr/bin/env bash
# open-note.sh — 保存済みの nb ノートを新しい WezTerm タブで開く（保存はしない）。
# save-answer / save-session の保存と「新タブで開く」を分離して使うためのコマンド。
#
# Usage: open-note.sh [-n <notebook>] [<target>]
#   -n <notebook>  対象 notebook (default: log)
#   <target>       省略時: notebook 内で最も新しいノートを開く
#                  数値/ファイル名/タイトル: nb セレクタとして解決して開く
#                  既存ファイルパス: そのファイルを直接開く
#
# 実表示は共有ヘルパー open-note-in-wezterm.sh に委譲する（ビューアは
# NB_VIEWER で変更可、既定 glow）。
set -uo pipefail

NOTEBOOK="log"
while getopts ":n:" opt; do
  case "$opt" in
    n) NOTEBOOK="$OPTARG" ;;
    :) echo "open-note: オプション -$OPTARG には引数が必要です" >&2; exit 1 ;;
    \?) echo "open-note: 不明なオプション -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
TARGET="${*:-}"

command -v nb >/dev/null || { echo "open-note: nb が見つかりません" >&2; exit 1; }
CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"
HELPER="$CFG/scripts/open-note-in-wezterm.sh"
[ -f "$HELPER" ] || { echo "open-note: $HELPER が見つかりません" >&2; exit 1; }

file=""
if [ -z "$TARGET" ]; then
  # 最新ノート: notebook ディレクトリ内を再帰的に mtime で並べて先頭
  nbdir="$(nb notebooks --paths 2>/dev/null | grep -E "/${NOTEBOOK}\$" | head -1)"
  [ -n "$nbdir" ] || { echo "open-note: notebook '${NOTEBOOK}' のパスを解決できません" >&2; exit 1; }
  file="$(find "$nbdir" -type f -name '*.md' -exec stat -f '%m %N' {} + 2>/dev/null \
            | sort -rn | head -1 | cut -d' ' -f2-)"
  [ -n "$file" ] || { echo "open-note: notebook '${NOTEBOOK}' にノートがありません" >&2; exit 1; }
elif [ -f "$TARGET" ]; then
  # 既存ファイルパスを直接
  file="$TARGET"
else
  # nb セレクタ（id / filename / title）として解決
  case "$TARGET" in
    *:*) sel="$TARGET" ;;                 # 既に notebook: 付き
    *)   sel="${NOTEBOOK}:${TARGET}" ;;
  esac
  file="$(nb show "$sel" --path 2>/dev/null | head -1)"
  { [ -n "$file" ] && [ -f "$file" ]; } \
    || { echo "open-note: ノートを解決できません: $TARGET" >&2; exit 1; }
fi

bash "$HELPER" "$file"
