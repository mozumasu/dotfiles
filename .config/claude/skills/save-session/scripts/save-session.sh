#!/usr/bin/env bash
# save-session.sh — 現在セッションの全会話を、トランスクリプト(JSONL)から
# 機械抽出して nb に保存する。WezTerm バッファ取得やサブエージェントによる
# Markdown 再生成を一切使わず、JSONL の本文をそのまま整形するため、
# モデルによる改変・捏造（ハルシネーション）が構造的に発生しない。
# （save-answer.sh と同じ思想の「セッション全体版」）
#
# Usage: save-session.sh [-n <notebook>] [-o] [<label>]
#   -n <notebook>  保存先 nb notebook (default: log)
#   -o             保存後に新しい WezTerm タブでノートを開く
#   <label>        タイトル/ファイル名に付与するラベル（省略時は最初の
#                  ユーザー入力から機械生成）
#
# 保存先: <notebook>:<owner-repo>/<YYYY-MM-DD>-<branch>/sessions/<timestamp>.md
#
# 注意: トランスクリプト JSONL の内部スキーマは Claude Code の公式ドキュメントで
#       文書化されていない。バージョンアップで壊れた場合に備え、抽出できなければ
#       何も保存せず非ゼロ終了する（誤った内容を書かないため）。
set -euo pipefail

NOTEBOOK="log"
OPEN=0
while getopts ":n:o" opt; do
  case "$opt" in
    n) NOTEBOOK="$OPTARG" ;;
    o) OPEN=1 ;;
    :) echo "save-session: オプション -$OPTARG には引数が必要です" >&2; exit 1 ;;
    \?) echo "save-session: 不明なオプション -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
LABEL="${*:-}"

command -v jq >/dev/null || { echo "save-session: jq が見つかりません" >&2; exit 1; }
command -v nb >/dev/null || { echo "save-session: nb が見つかりません" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JQ_PROG="$SCRIPT_DIR/session-format.jq"
[ -f "$JQ_PROG" ] || { echo "save-session: $JQ_PROG が見つかりません" >&2; exit 1; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"

# --- 現在セッションのトランスクリプトを特定（save-answer.sh と同じロジック） ---
# エンコード規則: 絶対パスの "/" と "." を "-" に置換
encoded="$(printf '%s' "$PWD" | perl -pe 's![/.]!-!g')"
proj="$CFG/projects/$encoded"

# CLAUDE_CODE_SESSION_ID（現在セッションの jsonl ファイル名）で正確に特定する。
# 公式には未文書のため、存在しない場合のフォールバックも用意する。
sid="${CLAUDE_CODE_SESSION_ID:-}"
files=()
if [ -n "$sid" ] && [ -f "$proj/$sid.jsonl" ]; then
  files=("$proj/$sid.jsonl")
elif [ -n "$sid" ]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$CFG/projects"/*/"$sid.jsonl" 2>/dev/null | head -1)
fi
# フォールバック: session id 不明なら現在 cwd プロジェクトの直近更新ファイル（単一）
if [ "${#files[@]}" -eq 0 ] && [ -d "$proj" ]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$proj"/*.jsonl 2>/dev/null | head -1)
fi
[ "${#files[@]}" -gt 0 ] || {
  echo "save-session: 現在セッションのトランスクリプトが見つかりません" >&2; exit 1; }

# --- JSONL から全会話を機械抽出（{count, title_src, body} を返す） ---
data="$(jq -s -f "$JQ_PROG" "${files[@]}")"
count="$(printf '%s' "$data" | jq -r '.count')"
title_src="$(printf '%s' "$data" | jq -r '.title_src')"
body="$(printf '%s' "$data" | jq -r '.body')"

if [ -z "${body//[$'\n\t ']/}" ] || [ "${count:-0}" -eq 0 ]; then
  echo "save-session: 会話を抽出できませんでした（保存を中止しました）" >&2
  exit 1
fi

# --- git コンテキスト（保存先フォルダ・タグ用。すべて決定論的） ---
OWNER_REPO="$(git remote get-url origin 2>/dev/null \
  | perl -pe 's{.*[:/]([^/]+)/([^/]+?)(?:\.git)?$}{$1-$2}')" \
  || OWNER_REPO=""
[ -n "$OWNER_REPO" ] || OWNER_REPO="local-$(basename "$PWD")"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")"
# ブランチ名の "/" はフォルダ区切りと衝突するため "-" に正規化
BRANCH_SAFE="$(printf '%s' "$BRANCH" | perl -pe 's![/ ]!-!g')"
DATE="$(date +%Y-%m-%d)"
FOLDER="${OWNER_REPO}/${DATE}-${BRANCH_SAFE}/sessions"

# --- タイトル決定（ラベル優先。未指定なら最初のユーザー入力から機械抽出） ---
if [ -n "$LABEL" ]; then
  TITLE="$LABEL"
else
  # slash command の場合は <command-args> の中身を採用、無ければタグ類を除去
  TITLE="$(printf '%s\n' "$title_src" \
    | perl -0pe 's!.*<command-args>(.*?)</command-args>.*!$1!s' \
    | perl -pe 's!<[^>]+>!!g' \
    | grep -m1 -E '\S' | perl -pe 's/^\s+//; s/\s+$//' | cut -c1-60 || true)"
  [ -n "$TITLE" ] || TITLE="session"
fi

ts="$(date +%Y%m%d%H%M%S)"
disp="$(date '+%Y-%m-%d %H:%M:%S')"

# --- nb 用のタグ（決定論的: session-log + repo + branch） ---
tag_repo="$(printf '%s' "$OWNER_REPO" | perl -pe 's![^A-Za-z0-9]+!-!g; s/^-|-$//g' | tr 'A-Z' 'a-z')"
tag_branch="$(printf '%s' "$BRANCH_SAFE" | perl -pe 's![^A-Za-z0-9]+!-!g; s/^-|-$//g' | tr 'A-Z' 'a-z')"

# --- ノート組み立て（見出し・タグ・注記・本文・メタデータ。本文は改変なし） ---
note="$(cat <<EOF
# ${TITLE} - ${disp}

\`#session-log\` \`#${tag_repo}\` \`#${tag_branch}\`

> [!NOTE]
> このログはセッションのトランスクリプト(JSONL)から機械抽出したものです（本文は改変なし・ハルシネーション防止）。tool の入力/出力は長い場合 truncate されます。

## 対話履歴

${body}

## メタデータ

- 作業ディレクトリ: \`${PWD}\`
- リポジトリ: \`${OWNER_REPO}\`
- ブランチ: \`${BRANCH}\`
- ターン数: ${count}
- 抽出元: \`${files[0]}\`
- 保存日時: ${disp}
EOF
)"

nb "${NOTEBOOK}:add" --folder "$FOLDER" --filename "${ts}.md" --content "$note" >/dev/null
echo "保存しました: ${NOTEBOOK}:${FOLDER}/${ts}.md  「${TITLE}」（${count}ターン）"

# -o 指定時は保存したノートを新しい WezTerm タブで開く
if [ "$OPEN" -eq 1 ]; then
  nbdir="$(nb notebooks --paths 2>/dev/null | grep -E "/${NOTEBOOK}\$" | head -1)"
  if [ -n "$nbdir" ]; then
    bash "$CFG/scripts/open-note-in-wezterm.sh" "${nbdir}/${FOLDER}/${ts}.md"
  else
    echo "save-session: notebook '${NOTEBOOK}' のパスを解決できず、新規タブ表示をスキップしました" >&2
  fi
fi
