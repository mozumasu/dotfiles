#!/usr/bin/env bash
# save-answer.sh — 直前の AI 回答をセッションのトランスクリプト(JSONL)から
# 機械抽出して nb に保存する。本文をモデルに再生成させないことで
# ハルシネーション（内容の改変・捏造）を構造的に防ぐ。
#
# Usage: save-answer.sh [-n <notebook>] [-c <count>] [-o] [<title>...]
#   -n <notebook>  保存先 nb notebook (default: log)
#   -c <count>     直近いくつの回答を保存するか (default: 1)
#                  2 以上を指定すると、直近 count 件の回答を時系列順
#                  （古い→新しい）で 1 つのノートに "---" 区切りで保存する。
#   -o             保存後に新しい WezTerm タブでノートを開く
#   <title...>     タイトル（省略時は本文の見出し/先頭行から機械生成）
#
# 注意: トランスクリプト JSONL の内部スキーマは Claude Code の公式ドキュメントで
#       文書化されていない。バージョンアップで壊れた場合に備え、抽出できなければ
#       何も保存せず非ゼロ終了する（誤った内容を書かないため）。
set -euo pipefail

NOTEBOOK="log"
COUNT=1
OPEN=0
while getopts ":n:c:o" opt; do
  case "$opt" in
    n) NOTEBOOK="$OPTARG" ;;
    c) COUNT="$OPTARG" ;;
    o) OPEN=1 ;;
    :) echo "save-answer: オプション -$OPTARG には引数が必要です" >&2; exit 1 ;;
    \?) echo "save-answer: 不明なオプション -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))
TITLE="${*:-}"

# COUNT は正の整数のみ許可（不正値で予期せぬスライスをしない）
case "$COUNT" in
  ''|*[!0-9]*) echo "save-answer: -c には正の整数を指定してください: $COUNT" >&2; exit 1 ;;
esac
[ "$COUNT" -ge 1 ] || { echo "save-answer: -c には 1 以上を指定してください: $COUNT" >&2; exit 1; }

command -v jq >/dev/null || { echo "save-answer: jq が見つかりません" >&2; exit 1; }
command -v nb >/dev/null || { echo "save-answer: nb が見つかりません" >&2; exit 1; }

CFG="${CLAUDE_CONFIG_DIR:-$HOME/.config/claude}"

# 現在プロジェクトのトランスクリプトディレクトリを特定する。
# エンコード規則: 絶対パスの "/" と "." を "-" に置換
#   例: /Users/ori.matsumoto/dotfiles -> -Users-ori-matsumoto-dotfiles
encoded="$(printf '%s' "$PWD" | perl -pe 's![/.]!-!g')"
proj="$CFG/projects/$encoded"

# プロジェクトdir は cwd 単位で全セッションが共有するため、timestamp 最大だけで
# 選ぶと別の同時起動セッションのメッセージを誤って拾う。Claude Code が Bash 実行時に
# 設定する環境変数 CLAUDE_CODE_SESSION_ID（= 現在セッションの jsonl ファイル名）で
# 現在セッションのトランスクリプトを正確に特定する。
# 注意: この環境変数は公式には未文書。存在しない場合のフォールバックも用意する。
sid="${CLAUDE_CODE_SESSION_ID:-}"
files=()
if [ -n "$sid" ] && [ -f "$proj/$sid.jsonl" ]; then
  files=("$proj/$sid.jsonl")
elif [ -n "$sid" ]; then
  # encoded proj が一致しない場合に備え全 projects から session ファイルを探す
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$CFG/projects"/*/"$sid.jsonl" 2>/dev/null | head -1)
fi
# フォールバック: session id 不明なら現在 cwd プロジェクトの直近更新ファイル（単一）
if [ "${#files[@]}" -eq 0 ] && [ -d "$proj" ]; then
  while IFS= read -r f; do files+=("$f"); done \
    < <(ls -t "$proj"/*.jsonl 2>/dev/null | head -1)
fi
[ "${#files[@]}" -gt 0 ] || {
  echo "save-answer: 現在セッションのトランスクリプトが見つかりません" >&2; exit 1; }

# 直近 COUNT 件の assistant 回答テキストを抽出する。
#  - 複数 jsonl に分割されている場合があるため全ファイルを横断 (jq -s)
#  - ファイルの mtime ではなく各行の timestamp で時系列ソート (sort_by)
#  - content は配列で text/tool_use が混在するため text ブロックのみ join
#  - モデル availability 通知などのノイズ行は除外
#  - 直近 COUNT 件を古い→新しい順で "---" 区切りに結合 (body)
#  - 実際に保存できた件数 (nsaved) とタイトル用の最新回答 (latest) も返す
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

# 空白のみ/空なら保存せず中止
if [ -z "${body//[$'\n\t ']/}" ]; then
  echo "save-answer: 直前の回答を抽出できませんでした（保存を中止しました）" >&2
  exit 1
fi

# タイトル決定（未指定なら最新回答から機械抽出。LLM は介在させない）
if [ -z "$TITLE" ]; then
  TITLE="$(printf '%s\n' "$latest" | grep -m1 -E '^#{1,4} ' \
            | perl -pe 's/^#{1,4}\s*//; s/\s+$//' || true)"
  [ -n "$TITLE" ] || \
    TITLE="$(printf '%s\n' "$latest" | grep -m1 -E '\S' | cut -c1-50)"
  # 複数件保存時はタイトルに件数を明示
  [ "$nsaved" -gt 1 ] && TITLE="${TITLE}（直近${nsaved}件）"
fi

ts="$(date +%Y%m%d%H%M%S)"
disp="$(date '+%Y-%m-%d %H:%M:%S')"

# nb に保存（見出し + 日時 + マーカータグ + 抽出した本文をそのまま）
note="$(printf '# %s - %s\n\n`#answer-log`\n\n%s\n' "$TITLE" "$disp" "$body")"

nb "${NOTEBOOK}:add" --filename "${ts}.md" --content "$note" >/dev/null
echo "保存しました: ${NOTEBOOK}:${ts}.md  「${TITLE}」（${nsaved}件）"

# -o 指定時は保存したノートを新しい WezTerm タブで開く
if [ "$OPEN" -eq 1 ]; then
  nbdir="$(nb notebooks --paths 2>/dev/null | grep -E "/${NOTEBOOK}\$" | head -1)"
  if [ -n "$nbdir" ]; then
    bash "$(dirname "${BASH_SOURCE[0]}")/open-note-in-wezterm.sh" "${nbdir}/${ts}.md"
  else
    echo "save-answer: notebook '${NOTEBOOK}' のパスを解決できず、新規タブ表示をスキップしました" >&2
  fi
fi
