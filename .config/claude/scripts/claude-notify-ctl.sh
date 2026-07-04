#!/usr/bin/env bash
# Claude Code 通知音の制御 (Raycast コマンドの実体)。
#   引数なし     … on/off をトグル
#   引数 0〜100 … 音量を設定して mute も解除
# 状態は ~/.local/state/claude-notify/ に持ち、Raycast 用スタブ
# (タイトルが状態表示を兼ねる生成物) を実行のたびに再生成する。

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-notify"
STUB="${HOME}/dotfiles/.config/raycast/scripts/claude-notify.sh"
mkdir -p "$STATE_DIR"

input="${1:-}"

if [ -z "$input" ]; then
  if [ -e "${STATE_DIR}/muted" ]; then
    rm "${STATE_DIR}/muted"
  else
    touch "${STATE_DIR}/muted"
  fi
else
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

cat >"$STUB" <<EOF
#!/usr/bin/env bash
#
# このファイルは claude-notify-ctl.sh が生成する (直接編集しない)
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Notification Sound: ${state}
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon ${icon}
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "音量 0-100 (空で on/off)", "optional": true }
# @raycast.description Claude Code の通知音を on/off・音量調整する
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

exec "\$HOME/.config/claude/scripts/claude-notify-ctl.sh" "\${1:-}"
EOF
chmod +x "$STUB"

echo "${icon} 通知音 ${state}"
