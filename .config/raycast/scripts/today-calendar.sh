#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Today's Calendar
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 📅
# @raycast.packageName Calendar
# @raycast.description 今日と明日の予定をクリップボードにコピー
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

if ! command -v icalBuddy >/dev/null 2>&1; then
  echo "icalBuddy が見つかりません。home-manager switch を実行してください。"
  exit 1
fi

# Load personal settings (e.g. INCLUDE_CALS="primary@example.com") if present.
# Sample: ~/.config/local/today-calendar.conf  (this path is in .gitignore)
LOCAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/local/today-calendar.conf"
# shellcheck disable=SC1090
[ -f "$LOCAL_CONFIG" ] && . "$LOCAL_CONFIG"

ical_args=(
  --bullet ""
  --noCalendarNames
  --noPropNames
  --includeEventProps "title,datetime"
  --timeFormat "%H:%M"
  --separateByDate
)
[ -n "${INCLUDE_CALS:-}" ] && ical_args+=(--includeCals "$INCLUDE_CALS")

raw=$(icalBuddy "${ical_args[@]}" eventsToday+1)

today_label="Today $(date +'%b %-d')"
tomorrow_label="Tomorrow $(date -v+1d +'%b %-d')"

output=$(printf '%s\n' "$raw" | awk \
  -v today_label="$today_label" \
  -v tomorrow_label="$tomorrow_label" '
  BEGIN { title = ""; last_section = ""; section = "" }
  /^today:/        { section = today_label; next }
  /^tomorrow:/     { section = tomorrow_label; next }
  /^-{3,}/         { next }
  /^[[:space:]]*$/ { next }
  /^[[:space:]]/ {
    line = $0
    sub(/^[[:space:]]+/, "", line)
    if (section != last_section) {
      if (last_section != "") print ""
      print section
      last_section = section
    }
    print line "  " title
    next
  }
  { title = $0 }
')

if [ -z "$output" ]; then
  output="今日と明日の予定はありません。"
fi

printf '%s' "$output" | pbcopy
printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
