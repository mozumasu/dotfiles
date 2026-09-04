#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Clipboard to Tech Scrap
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 📚
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "追加の指示 (任意)", "optional": true }
# @raycast.description クリップボードの内容を固有名詞を除いた技術スクラップに要約してコピー
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

# 執筆ルール (匿名化・構成・引用) は Claude Code の /tech-scrap スキルと共有する
rules_file="$HOME/.config/claude/skills/tech-scrap/scrap-rules.md"
if [ ! -f "$rules_file" ]; then
  echo "執筆ルールが見つかりません: $rules_file"
  exit 1
fi

prompt="以下のテキストを、あとで見返せる汎用的な技術スクラップ (ナレッジノート) にマークダウンで要約してください。

$(<"$rules_file")

# 出力
- 出力はマークダウン本文のみ。前置きや説明、コードフェンスでの全体囲みは不要"
if [ -n "$extra" ]; then
  prompt="$prompt

# 追加の指示
$extra"
fi

# テキスト変換だけの用途。ツールとスキルを無効化し、スキルの誤発動やファイル作成を防ぐ
result=$(printf '%s' "$input" | claude -p "$prompt" --model sonnet --tools "" --disable-slash-commands)

if [ -z "$result" ]; then
  echo "claude から出力が得られませんでした。"
  exit 1
fi

if [ -z "${NO_PBCOPY:-}" ]; then
  printf '%s\n' "$result" | pbcopy
fi
printf '%s\n' "$result"
