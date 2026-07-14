#!/usr/bin/env bash
# Claude Code の git push 許可の制御 (Raycast コマンドの実体)。
#   引数なし      … on/off をトグル
#   引数 on / off … 明示的に設定
# 状態は ~/.local/state/claude-git-push/allowed の有無で持ち
# (prevent-git-push.py がこれを参照する)、Raycast 用スタブ
# (タイトルが状態表示を兼ねる生成物) を実行のたびに再生成する。

set -euo pipefail

STATE_DIR="${HOME}/.local/state/claude-git-push"
STATE_FILE="${STATE_DIR}/allowed"
STUB="${HOME}/dotfiles/.config/raycast/scripts/claude-git-push.sh"
mkdir -p "$STATE_DIR"

input="${1:-}"

case "$input" in
"")
  if [ -e "$STATE_FILE" ]; then
    rm "$STATE_FILE"
  else
    touch "$STATE_FILE"
  fi
  ;;
on) touch "$STATE_FILE" ;;
off) rm -f "$STATE_FILE" ;;
*)
  echo "on / off を指定してください (空でトグル)"
  exit 1
  ;;
esac

if [ -e "$STATE_FILE" ]; then
  state="ALLOWED" icon="🚀"
else
  state="BLOCKED" icon="🔒"
fi

cat >"$STUB" <<EOF
#!/usr/bin/env bash
#
# このファイルは claude-git-push-ctl.sh が生成する (直接編集しない)
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Claude Git Push: ${state}
# @raycast.mode compact
#
# Optional parameters:
# @raycast.icon ${icon}
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "on / off (空でトグル)", "optional": true }
# @raycast.description Claude Code の git push 許可を on/off する
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

exec "\$HOME/.config/claude/scripts/claude-git-push-ctl.sh" "\${1:-}"
EOF
chmod +x "$STUB"

echo "${icon} git push ${state}"
