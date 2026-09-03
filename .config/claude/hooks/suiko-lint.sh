#!/bin/bash
# suiko で日本語散文を lint し、finding があれば整形して stderr に出し exit 2 を返す。
#
# 使い方: suiko-lint.sh <file|-> [genre] [min_severity] [label] [mode]
#
# mode=block: finding を stderr に出し exit 2 (Claude に修正させる)
# mode=hint : PostToolUse の additionalContext として渡し exit 0 (作業を止めない)
#
# suiko は文数が少ない文書では統計系検出器 (low_burstiness 等) を自ら抑制するため、
# 数文しかない issue 本文でも翻訳調・AI 定型の局所検出だけが残る。

set -u

TARGET="${1:?usage: suiko-lint.sh <file|-> [genre] [min_severity] [label] [mode]}"
GENRE="${2:-tech}"
MIN_SEVERITY="${3:-info}"
LABEL="${4:-$TARGET}"
MODE="${5:-block}"

command -v suiko >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

if [ "$TARGET" = "-" ]; then
  JSON=$(suiko lint --json --genre "$GENRE" - 2>/dev/null)
else
  [ -f "$TARGET" ] || exit 0
  JSON=$(suiko lint --json --genre "$GENRE" "$TARGET" 2>/dev/null)
fi

[ -z "$JSON" ] && exit 0
jq -e '.findings' >/dev/null 2>&1 <<<"$JSON" || exit 0

# 1 文以下は推敲の対象にならない
SENTENCES=$(jq -r '.stats.total_sentences // 0' <<<"$JSON")
[ "$SENTENCES" -lt 2 ] && exit 0

REPORT=$(jq -r --arg min "$MIN_SEVERITY" '
  {info: 0, warn: 1, critical: 2} as $rank
  | [.findings[] | select(($rank[.severity] // 0) >= ($rank[$min] // 0))]
  | .[]
  | "  L\(.line) [\(.severity)] \(.category): \(.excerpt)\n      \(.detail)"
' <<<"$JSON")

[ -z "$REPORT" ] && exit 0

MESSAGE="$LABEL: suiko が日本語の推敲余地を検出しました。

$REPORT

翻訳調 (〜することができる)・AI 的な定型・単調なリズムの指摘です。
妥当な指摘は直し、意図的な表現なら .suiko.toml の allow に理由付きで追加してください。"

if [ "$MODE" = "hint" ]; then
  jq -n --arg ctx "$MESSAGE" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
  exit 0
fi

echo "$MESSAGE" >&2
exit 2
