#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Claude Notification Sound
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon 🔔
# @raycast.packageName Claude
# @raycast.description Claude Code の通知音を on/off する
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-notify"
mkdir -p "$STATE_DIR"

if [ -e "${STATE_DIR}/muted" ]; then
  rm "${STATE_DIR}/muted"
  echo "🔔 通知音 ON"
else
  touch "${STATE_DIR}/muted"
  echo "🔕 通知音 OFF"
fi
