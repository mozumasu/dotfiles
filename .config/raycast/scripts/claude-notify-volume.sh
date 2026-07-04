#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set Claude Notification Volume
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 🔊
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "音量 0-100", "optional": false }
# @raycast.description Claude Code の通知音量を設定する (0-100)
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-notify"
mkdir -p "$STATE_DIR"

input="$1"
if ! [[ "$input" =~ ^[0-9]+$ ]] || [ "$input" -gt 100 ]; then
  echo "0〜100 の整数を指定してください"
  exit 1
fi

volume=$(perl -e "printf '%.2f', $input / 100")
echo "$volume" >"${STATE_DIR}/volume"

afplay -v "$volume" /System/Library/Sounds/Glass.aiff &
echo "🔊 通知音量を ${input}% に設定"
