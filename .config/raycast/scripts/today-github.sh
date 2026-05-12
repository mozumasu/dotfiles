#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Today's GitHub
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🐙
# @raycast.packageName Calendar
# @raycast.description 今日 close した issue (assignee:@me) をクリップボードにコピー
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI が見つかりません。home-manager switch を実行してください。"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI 未認証。gh auth login を実行してください。"
  exit 1
fi

today=$(date +'%Y-%m-%d')

raw=$(gh search issues \
  --assignee=@me \
  --state=closed \
  "closed:>=${today}" \
  --limit=100 \
  --json title,number,repository \
  --jq '.[] | "[\(.repository.nameWithOwner)#\(.number)] \(.title)"')

if [ -z "$raw" ]; then
  output="GitHub Closed Today (${today})
今日 close した issue はありません。"
else
  output="GitHub Closed Today (${today})
${raw}"
fi

if [ "${NO_PBCOPY:-}" = "1" ]; then
  printf '%s\n' "$output"
else
  printf '%s' "$output" | pbcopy
  printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
fi
