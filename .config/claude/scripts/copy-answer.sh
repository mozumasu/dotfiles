#!/usr/bin/env bash
# copy-answer.sh — 直前の AI 回答をセッションのトランスクリプト(JSONL)から
# 機械抽出してクリップボードにコピーする。
# save-answer.sh のクリップボード版。本文はモデルに再生成させないので
# ハルシネーション（内容の改変）は発生しない。
#
# Usage: copy-answer.sh [nth] [-c <count> | -n <nth>] [-t] [-b] [-o <path>]
#   nth         -n の省略形。ビルトイン /copy N と同じく N 番目前の回答を
#               1 件コピーする (例: copy-answer.sh 2)
#   -c <count>  直近いくつの回答をコピーするか (default: 1)
#               2 以上なら時系列順（古い→新しい）で "---" 区切り。
#   -n <nth>    N 番目前の回答を 1 件だけコピー (1 = 最新)。-c と排他。
#               範囲外（回答数より大きい N）はエラー。
#   -t          先頭にタイトル行（`# <title> - <日時>`）を付ける
#   -b          コードブロック（``` フェンス内）のみ抽出する
#   -l          コードブロックの一覧を表示するだけ（コピーしない）
#   -B <k>      k 番目のコードブロックのみコピーする (1 始まり)
#   -o <path>   クリップボードの代わりにファイルへ書き出す
set -euo pipefail

COUNT=1
NTH=0
WITH_TITLE=0
CODE_ONLY=0
OUT_FILE=""
COUNT_SET=0

# 裸の数値 1 つを先頭で受け付ける (-n の省略形。ビルトイン /copy N と同じ挙動)
NTH_SET=0
if [ "$#" -gt 0 ]; then
  case "$1" in
    *[!0-9]*|'') ;;
    *) NTH="$1"; NTH_SET=1; shift ;;
  esac
fi

LIST_BLOCKS=0
BLOCK_N=0
while getopts ":c:n:o:B:tbl" opt; do
  case "$opt" in
    c) [ "$COUNT_SET" -eq 0 ] || { echo "copy-answer: 件数が重複指定されています" >&2; exit 1; }
       COUNT="$OPTARG"; COUNT_SET=1 ;;
    n) [ "$NTH_SET" -eq 0 ] || { echo "copy-answer: N が重複指定されています" >&2; exit 1; }
       NTH="$OPTARG"; NTH_SET=1 ;;
    o) OUT_FILE="$OPTARG" ;;
    t) WITH_TITLE=1 ;;
    b) CODE_ONLY=1 ;;
    l) LIST_BLOCKS=1 ;;
    B) BLOCK_N="$OPTARG" ;;
    :) echo "copy-answer: オプション -$OPTARG には引数が必要です" >&2; exit 1 ;;
    \?) echo "copy-answer: 不明なオプション -$OPTARG" >&2; exit 1 ;;
  esac
done

shift $((OPTIND - 1))
[ "$#" -eq 0 ] || { echo "copy-answer: 不明な引数です: $*" >&2; exit 1; }

case "$COUNT" in
  ''|*[!0-9]*) echo "copy-answer: -c には正の整数を指定してください: $COUNT" >&2; exit 1 ;;
esac
[ "$COUNT" -ge 1 ] || { echo "copy-answer: -c には 1 以上を指定してください: $COUNT" >&2; exit 1; }
case "$NTH" in
  *[!0-9]*) echo "copy-answer: -n には正の整数を指定してください: $NTH" >&2; exit 1 ;;
esac
if [ "$NTH_SET" -eq 1 ] && [ "$NTH" -lt 1 ]; then
  echo "copy-answer: N には 1 以上を指定してください: $NTH" >&2; exit 1
fi
case "$BLOCK_N" in
  *[!0-9]*) echo "copy-answer: -B には正の整数を指定してください: $BLOCK_N" >&2; exit 1 ;;
esac
if [ "$BLOCK_N" -gt 0 ] && [ "$CODE_ONLY" -eq 1 ]; then
  echo "copy-answer: -B と -b は同時に指定できません" >&2; exit 1
fi
if [ "$LIST_BLOCKS" -eq 1 ] && { [ "$BLOCK_N" -gt 0 ] || [ "$CODE_ONLY" -eq 1 ]; }; then
  echo "copy-answer: -l は -B / -b と同時に指定できません" >&2; exit 1
fi
if [ "$NTH" -gt 0 ] && [ "$COUNT_SET" -eq 1 ]; then
  echo "copy-answer: -n と -c は同時に指定できません" >&2; exit 1
fi

command -v jq >/dev/null || { echo "copy-answer: jq が見つかりません" >&2; exit 1; }
if [ -z "$OUT_FILE" ]; then
  command -v pbcopy >/dev/null || { echo "copy-answer: pbcopy が見つかりません（macOS 専用）" >&2; exit 1; }
fi

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

data="$(jq -rs --argjson n "$COUNT" --argjson nth "$NTH" '
  [ .[] | select(.type=="assistant"
        and (.message.content | type == "array")
        and (any(.message.content[]; .type == "text")))
    | { ts: .timestamp,
        text: (.message.content | map(select(.type=="text").text) | join("\n")) } ]
  | map(select(.text | test("is currently unavailable\\. Learn more:") | not))
  | map(select((.text | gsub("\\s"; "") | length) > 0))
  | sort_by(.ts)
  | length as $total
  | (if $nth > 0 then
       (if $nth > $total then [] else [.[$total - $nth]] end)
     elif length > $n then .[length - $n:]
     else . end) as $sel
  | { total:  $total,
      nsaved: ($sel | length),
      body:   ($sel | map(.text) | join("\n\n---\n\n")),
      latest: ($sel | if length == 0 then "" else .[-1].text end) }
  | @json
' "${files[@]}")"

total="$(printf '%s' "$data" | jq -r '.total')"
nsaved="$(printf '%s' "$data" | jq -r '.nsaved')"
body="$(printf '%s' "$data" | jq -r '.body')"
latest="$(printf '%s' "$data" | jq -r '.latest')"

if [ "$NTH" -gt 0 ] && [ "$NTH" -gt "$total" ]; then
  echo "copy-answer: -n $NTH は範囲外です（このセッションの回答は ${total} 件）" >&2
  exit 1
fi

if [ -z "${body//[$'\n\t ']/}" ]; then
  echo "copy-answer: 直前の回答を抽出できませんでした（コピーを中止しました）" >&2
  exit 1
fi

if [ "$LIST_BLOCKS" -eq 1 ]; then
  list="$(printf '%s\n' "$body" | perl -CSD -Mutf8 -ne '
    if (/^\s*(?:`{3,}|~{3,})\s*(\S*)/) {
      if ($in) { $in = 0;
        printf "%d) [%s] %d行: %s\n", $i, ($lang eq "" ? "text" : $lang), $cnt, $first;
      } else { $in = 1; $i++; $lang = $1; $cnt = 0; $first = "" }
      next;
    }
    if ($in) { $cnt++;
      if ($first eq "") { ($first = $_) =~ s/\s+$//; $first = substr($first, 0, 60) }
    }
  ')"
  if [ -z "$list" ]; then
    echo "copy-answer: 対象の回答にコードブロックが見つかりませんでした" >&2
    exit 1
  fi
  printf '%s\n' "$list"
  exit 0
fi

if [ "$BLOCK_N" -gt 0 ]; then
  body="$(printf '%s\n' "$body" | K="$BLOCK_N" perl -ne '
    if (/^\s*(?:`{3,}|~{3,})/) {
      if ($in) { $in = 0 } else { $in = 1; $i++ }
      next;
    }
    print if $in && $i == $ENV{K};
  ')"
  if [ -z "${body//[$'\n\t ']/}" ]; then
    echo "copy-answer: -B $BLOCK_N は範囲外です（コードブロック数を -l で確認できます）" >&2
    exit 1
  fi
fi

if [ "$CODE_ONLY" -eq 1 ]; then
  body="$(printf '%s\n' "$body" | perl -ne '
    if (/^\s*(`{3,}|~{3,})/) {
      if ($in) { $in = 0; push @blocks, $buf; $buf = "" }
      else { $in = 1 }
      next;
    }
    $buf .= $_ if $in;
    END { print join("\n", @blocks) }
  ')"
  if [ -z "${body//[$'\n\t ']/}" ]; then
    echo "copy-answer: 対象の回答にコードブロックが見つかりませんでした" >&2
    exit 1
  fi
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

bytes="$(printf '%s' "$out" | wc -c | tr -d ' ')"
if [ -n "$OUT_FILE" ]; then
  printf '%s' "$out" > "$OUT_FILE"
  echo "ファイルに書き出しました: ${OUT_FILE} / ${nsaved}件 / ${bytes} bytes"
else
  printf '%s' "$out" | pbcopy
  echo "クリップボードにコピーしました: ${nsaved}件 / ${bytes} bytes"
fi
