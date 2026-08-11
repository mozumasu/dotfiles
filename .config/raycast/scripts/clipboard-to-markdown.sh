#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clipboard to Markdown
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 📝
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "追加の指示 (任意)", "optional": true }
# @raycast.description クリップボードのテキストを claude -p でマークダウンに整形してコピー
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

# Raycast の最小 PATH では nix / mise 管理のバイナリが見えないため明示的に追加する
export PATH="$HOME/.local/share/mise/shims:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

# 認証情報は ~/.config/claude 配下にある (shell 設定と同じ値。無いと Not logged in になる)
export CLAUDE_CONFIG_DIR="$HOME/.config/claude"

# ロケール未設定だと pbpaste が日本語を Shift-JIS で出力し文字化けする
export LC_CTYPE=UTF-8

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI が見つかりません。PATH を確認してください。"
  exit 1
fi

input=$(pbpaste)
if [ -z "$input" ]; then
  echo "クリップボードが空です。"
  exit 1
fi

extra="${1:-}"

prompt="以下のテキストを読みやすいマークダウンに整形してください。
- 内容の追加・削除・要約はせず、構造化 (見出し・箇条書き・コードブロック・表など) のみ行う
- コード・コマンド・ログ・設定ファイルなどの部分は必ずコードブロックで囲み、言語が分かる場合は言語指定を付ける (例: \`\`\`sh)
- 文中に登場するコマンド名・ファイル名・識別子はインラインコード (\`) にする
- 出力はマークダウン本文のみ。前置きや説明、コードフェンスでの全体囲みは不要"
if [ -n "$extra" ]; then
  prompt="$prompt
- 追加の指示: $extra"
fi

result=$(printf '%s' "$input" | claude -p "$prompt" --model haiku)

if [ -z "$result" ]; then
  echo "claude から出力が得られませんでした。"
  exit 1
fi

if [ -z "${NO_PBCOPY:-}" ]; then
  printf '%s\n' "$result" | pbcopy
fi
printf '%s\n' "$result"
