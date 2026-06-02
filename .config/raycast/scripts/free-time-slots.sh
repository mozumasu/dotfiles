#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Free Time Slots
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🕐
# @raycast.packageName Calendar
# @raycast.description 指定日の空き時間をクリップボードにコピー
# @raycast.argument1 { "type": "text", "placeholder": "today / tomorrow / 2026-06-03 / +3", "optional": true }
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

if ! command -v icalBuddy >/dev/null 2>&1; then
  echo "icalBuddy が見つかりません。home-manager switch を実行してください。"
  exit 1
fi

LOCAL_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/local/today-calendar.conf"
# shellcheck disable=SC1090
[ -f "$LOCAL_CONFIG" ] && . "$LOCAL_CONFIG"

START_HOUR="${START_HOUR:-9}"
END_HOUR="${END_HOUR:-18}"

arg="${1:-today}"

case "$arg" in
  today|"")
    target_date=$(date +'%Y-%m-%d')
    ;;
  tomorrow)
    target_date=$(date -v+1d +'%Y-%m-%d')
    ;;
  +[0-9]*)
    days="${arg#+}"
    target_date=$(date -v+"${days}"d +'%Y-%m-%d')
    ;;
  [0-9][0-9]-[0-9][0-9])
    target_date="$(date +'%Y')-${arg}"
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    target_date="$arg"
    ;;
  *)
    echo "日付の形式が不正です: $arg"
    echo "使用可能: today, tomorrow, 06-03, 2026-06-03, +3"
    exit 1
    ;;
esac

ical_args=(
  --bullet ""
  --noCalendarNames
  --noPropNames
  --includeEventProps "datetime"
  --timeFormat "%H:%M"
  --dateFormat ""
  --excludeAllDayEvents
  --noRelativeDates
)
[ -n "${INCLUDE_CALS:-}" ] && ical_args+=(--includeCals "$INCLUDE_CALS")

raw=$(icalBuddy "${ical_args[@]}" \
  "eventsFrom:${target_date} 00:00:00" "to:${target_date} 23:59:59" 2>/dev/null || true)

output=$(printf '%s\n' "$raw" | awk -v start_hour="$START_HOUR" -v end_hour="$END_HOUR" '
BEGIN {
  work_start = start_hour * 60
  work_end = end_hour * 60
  n = 0
}
/^[0-9][0-9]:[0-9][0-9] - [0-9][0-9]:[0-9][0-9]/ {
  split($1, a, ":")
  ev_start = a[1] * 60 + a[2]
  split($3, b, ":")
  ev_end = b[1] * 60 + b[2]

  if (ev_end <= work_start || ev_start >= work_end) next
  if (ev_start < work_start) ev_start = work_start
  if (ev_end > work_end) ev_end = work_end

  n++
  starts[n] = ev_start
  ends[n] = ev_end
}
END {
  for (i = 2; i <= n; i++) {
    s = starts[i]; e = ends[i]
    j = i - 1
    while (j >= 1 && starts[j] > s) {
      starts[j+1] = starts[j]
      ends[j+1] = ends[j]
      j--
    }
    starts[j+1] = s
    ends[j+1] = e
  }

  m = 0
  for (i = 1; i <= n; i++) {
    if (m == 0 || starts[i] > mends[m]) {
      m++
      mstarts[m] = starts[i]
      mends[m] = ends[i]
    } else if (ends[i] > mends[m]) {
      mends[m] = ends[i]
    }
  }

  cursor = work_start
  found = 0
  for (i = 1; i <= m; i++) {
    if (mstarts[i] > cursor) {
      printf "%02d:%02d - %02d:%02d\n", int(cursor/60), cursor%60, int(mstarts[i]/60), mstarts[i]%60
      found++
    }
    if (mends[i] > cursor) cursor = mends[i]
  }
  if (cursor < work_end) {
    printf "%02d:%02d - %02d:%02d\n", int(cursor/60), cursor%60, int(work_end/60), work_end%60
    found++
  }
  if (found == 0) {
    print "空き時間はありません。"
  }
}
')

header="📅 ${target_date} の空き時間"
output="${header}

${output}"

if [ "${NO_PBCOPY:-}" = "1" ]; then
  printf '%s\n' "$output"
else
  printf '%s' "$output" | pbcopy
  printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
fi
