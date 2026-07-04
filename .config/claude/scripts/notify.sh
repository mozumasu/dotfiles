#!/usr/bin/env bash
# Claude Code の通知 (デスクトップ通知 + サウンド)。
# サウンドは ~/.local/state/claude-notify/ で制御する:
#   muted  … 存在すれば消音 (デスクトップ通知は出す)
#   volume … 0.0〜1.0 の音量 (未設定時は 1.0)

STATE_DIR="${HOME}/.local/state/claude-notify"
TITLE="${1:-Claude}"

terminal-notifier -title "$TITLE" -message "$(basename "$PWD")" &

[ -e "${STATE_DIR}/muted" ] && exit 0

volume=1.0
[ -f "${STATE_DIR}/volume" ] && volume=$(<"${STATE_DIR}/volume")

afplay -v "$volume" /System/Library/Sounds/Glass.aiff
