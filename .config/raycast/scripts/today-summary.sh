#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Today's Summary
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 📋
# @raycast.packageName Calendar
# @raycast.description 今日のカレンダーと close issue をまとめてクリップボードに
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if calendar=$(NO_PBCOPY=1 "$SCRIPT_DIR/today-calendar.sh" 2>&1); then
  :
else
  calendar="(calendar fetch failed)
${calendar}"
fi

if github=$(NO_PBCOPY=1 "$SCRIPT_DIR/today-github.sh" 2>&1); then
  :
else
  github="(github fetch failed)
${github}"
fi

output=$(printf '%s\n\n%s' "$calendar" "$github")

printf '%s' "$output" | pbcopy
printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
