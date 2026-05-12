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

calendar=$(NO_PBCOPY=1 "$SCRIPT_DIR/today-calendar.sh") || calendar="(calendar fetch failed)"
github=$(NO_PBCOPY=1 "$SCRIPT_DIR/today-github.sh") || github="(github fetch failed)"

output=$(printf '%s\n\n%s' "$calendar" "$github")

printf '%s' "$output" | pbcopy
printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
