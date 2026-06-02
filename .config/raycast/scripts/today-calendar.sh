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

dow=$(date +%u)
if [ "$dow" -eq 5 ]; then
  range=3
  next_label="Monday $(date -v+3d +'%b %-d')"
  next_date=$(date -v+3d +'%Y-%m-%d')
else
  range=1
  next_label="Tomorrow $(date -v+1d +'%b %-d')"
  next_date=$(date -v+1d +'%Y-%m-%d')
fi
today_date=$(date +'%Y-%m-%d')
today_label="Today $(date +'%b %-d')"

ical_args=(
  --bullet ""
  --noCalendarNames
  --noPropNames
  --includeEventProps "title,datetime"
  --timeFormat "%H:%M"
  --separateByDate
  --noRelativeDates
  --dateFormat "%Y-%m-%d"
)
[ -n "${INCLUDE_CALS:-}" ] && ical_args+=(--includeCals "$INCLUDE_CALS")

raw=$(icalBuddy "${ical_args[@]}" "eventsToday+${range}")

output=$(printf '%s\n' "$raw" | awk \
  -v today_label="$today_label" \
  -v next_label="$next_label" \
  -v today_date="$today_date" \
  -v next_date="$next_date" '
  BEGIN { title = ""; last_section = ""; section = ""; skip = 0 }
  /^[0-9]{4}-[0-9]{2}-[0-9]{2}:/ {
    d = $0; sub(/:$/, "", d)
    if (d == today_date) { section = today_label; skip = 0 }
    else if (d == next_date) { section = next_label; skip = 0 }
    else { skip = 1 }
    next
  }
  /^-{3,}/         { next }
  /^[[:space:]]*$/ { next }
  skip { next }
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

if [ "${NO_PBCOPY:-}" = "1" ]; then
  printf '%s\n' "$output"
else
  printf '%s' "$output" | pbcopy
  printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
fi
