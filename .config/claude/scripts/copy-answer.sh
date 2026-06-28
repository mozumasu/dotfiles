#!/usr/bin/env bash
# copy-answer.sh — 直前の AI 回答をセッションのトランスクリプト(JSONL)から
# 機械抽出してクリップボードにコピーする。
# save-answer.sh のクリップボード版。本文はモデルに再生成させないので
# ハルシネーション（内容の改変）は発生しない。
#
# Usage: copy-answer.sh [-c <count>] [-t]
#   -c <count>  直近いくつの回答をコピーするか (default: 1)
#               2 以上なら時系列順（古い→新しい）で "---" 区切り。
#   -t          先頭にタイトル行（`# <title> - <日時>`）を付ける
set -euo pipefail

COUNT=1
WITH_TITLE=0
while getopts ":c:t" opt; do
  case "$opt" in
    c) COUNT="$OPTARG" ;;
    t) WITH_TITLE=1 ;;
    :) echo "copy-answer: オプション -$OPTARG には引数が必要です" >&2; exit 1 ;;
    \?) echo "copy-answer: 不明なオプション -$OPTARG" >&2; exit 1 ;;
  esac
done

case "$COUNT" in
  ''|*[!0-9]*) echo "copy-answer: -c には正の整数を指定してください: $COUNT" >&2; exit 1 ;;
esac
[ "$COUNT" -ge 1 ] || { echo "copy-answer: -c には 1 以上を指定してください: $COUNT" >&2; exit 1; }

command -v jq >/dev/null || { echo "copy-answer: jq が見つかりません" >&2; exit 1; }
command -v pbcopy >/dev/null || { echo "copy-answer: pbcopy が見つかりません（macOS 専用）" >&2; exit 1; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"
encoded="$(printf '%s' "$PWD" | perl -pe 's![/.]!-!g')"
proj="$CFG/projects/$encoded"

sid="${CLAUDE_CODE_SESSION_ID:-}"
files=()
if [ -n "$sid" ] && [ -f "$proj/$sid.jsonl" ]; then
  files=("$proj/$sid.jsonl")
elif [ -n "$sid" ]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$CFG/projects"/*/"$sid.jsonl" 2>/dev/null | head -1)
fi
if [ "${#files[@]}" -eq 0 ] && [ -d "$proj" ]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$proj"/*.jsonl 2>/dev/null | head -1)
fi
[ "${#files[@]}" -gt 0 ] || {
  echo "copy-answer: 現在セッションのトランスクリプトが見つかりません" >&2; exit 1; }

data="$(jq -rs --argjson n "$COUNT" '
  [ .[] | select(.type=="assistant"
        and (.message.content | type == "array")
        and (any(.message.content[]; .type == "text")))
    | { ts: .timestamp,
        text: (.message.content | map(select(.type=="text").text) | join("\n")) } ]
  | map(select(.text | test("is currently unavailable\\. Learn more:") | not))
  | map(select((.text | gsub("\\s"; "") | length) > 0))
  | sort_by(.ts)
  | (if length > $n then .[length - $n:] else . end) as $sel
  | { nsaved: ($sel | length),
      body:   ($sel | map(.text) | join("\n\n---\n\n")),
      latest: ($sel | if length == 0 then "" else .[-1].text end) }
  | @json
' "${files[@]}")"

nsaved="$(printf '%s' "$data" | jq -r '.nsaved')"
body="$(printf '%s' "$data" | jq -r '.body')"
latest="$(printf '%s' "$data" | jq -r '.latest')"

if [ -z "${body//[$'\n\t ']/}" ]; then
  echo "copy-answer: 直前の回答を抽出できませんでした（コピーを中止しました）" >&2
  exit 1
fi

if [ "$WITH_TITLE" -eq 1 ]; then
  TITLE="$(printf '%s\n' "$latest" | grep -m1 -E '^#{1,4} ' \
            | perl -pe 's/^#{1,4}\s*//; s/\s+$//' || true)"
  [ -n "$TITLE" ] || \
    TITLE="$(printf '%s\n' "$latest" | grep -m1 -E '\S' | cut -c1-50)"
  [ "$nsaved" -gt 1 ] && TITLE="${TITLE}（直近${nsaved}件）"
  disp="$(date '+%Y-%m-%d %H:%M:%S')"
  out="$(printf '# %s - %s\n\n%s\n' "$TITLE" "$disp" "$body")"
else
  out="$body"
fi

printf '%s' "$out" | pbcopy
bytes="$(printf '%s' "$out" | wc -c | tr -d ' ')"
echo "クリップボードにコピーしました: ${nsaved}件 / ${bytes} bytes"
