#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Notification Sound: OFF
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 🔕
# @raycast.packageName Claude
# @raycast.description Claude Code の通知音を on/off する
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

# タイトル・アイコン行は現在の状態の表示を兼ねており、
# トグル時にこのスクリプト自身が書き換える。

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-notify"
mkdir -p "$STATE_DIR"

SELF="${BASH_SOURCE[0]}"

if [ -e "${STATE_DIR}/muted" ]; then
  rm "${STATE_DIR}/muted"
  state="ON" icon="🔔"
else
  touch "${STATE_DIR}/muted"
  state="OFF" icon="🔕"
fi

perl -pi -e "s/^# \@raycast\.title .*/# \@raycast.title Claude Notification Sound: ${state}/; s/^# \@raycast\.icon .*/# \@raycast.icon ${icon}/" "$SELF"

echo "${icon} 通知音 ${state}"
