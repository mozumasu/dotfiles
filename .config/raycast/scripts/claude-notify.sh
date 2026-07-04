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
# @raycast.argument1 { "type": "text", "placeholder": "音量 0-100 (空で on/off)", "optional": true }
# @raycast.description Claude Code の通知音を on/off・音量調整する
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

# タイトル・アイコン行は現在の状態の表示を兼ねており、
# 実行のたびにこのスクリプト自身が書き換える。

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-notify"
mkdir -p "$STATE_DIR"

SELF="${BASH_SOURCE[0]}"
input="${1:-}"

if [ -z "$input" ]; then
  # 引数なし: on/off をトグル
  if [ -e "${STATE_DIR}/muted" ]; then
    rm "${STATE_DIR}/muted"
  else
    touch "${STATE_DIR}/muted"
  fi
else
  # 引数あり: 音量を設定して mute も解除
  if ! [[ "$input" =~ ^[0-9]+$ ]] || [ "$input" -gt 100 ]; then
    echo "0〜100 の整数を指定してください"
    exit 1
  fi
  perl -e "printf '%.2f', $input / 100" >"${STATE_DIR}/volume"
  rm -f "${STATE_DIR}/muted"
fi

volume=1.0
[ -f "${STATE_DIR}/volume" ] && volume=$(<"${STATE_DIR}/volume")
percent=$(perl -e "printf '%d', $volume * 100")

if [ -e "${STATE_DIR}/muted" ]; then
  state="OFF" icon="🔕"
else
  state="ON (${percent}%)" icon="🔔"
  afplay -v "$volume" /System/Library/Sounds/Glass.aiff &
fi

perl -pi -e "s/^# \@raycast\.title .*/# \@raycast.title Claude Notification Sound: ${state}/; s/^# \@raycast\.icon .*/# \@raycast.icon ${icon}/" "$SELF"

echo "${icon} 通知音 ${state}"
