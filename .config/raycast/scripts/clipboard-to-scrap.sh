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

prompt='以下のテキストを、あとで見返せる汎用的な技術スクラップ (ナレッジノート) にマークダウンで要約してください。

# 匿名化 (最重要)
- 社内プロダクト名・社名・プロジェクト名・環境名・社内サービス名などの固有名詞は除去し、「アプリケーション」「対象環境」などの一般名詞に置き換える
- OSS・パブリックな製品・技術の名前 (Docker, AWS, ECR, crane など) はそのまま残す
- 元テキストの個別事情は「使用に至った背景」のような形で一般化して書き、特定の組織を推測できる情報を残さない
- 公式ドキュメントなどからの引用文と、元テキストに含まれる URL (公式ドキュメント・GitHub・参考記事など) は削らずそのまま残す
- 引用の出典 (ドキュメント名・ページタイトルなど) が分かる場合は、引用ブロックの直後に「出典: <名前>」として残す
- 引用ブロック内の段落間の空行 (`>` のみの行) は入れず、連続した `>` 行に詰める

# 構成・スタイル
- 冒頭は `# <技術名> <一言でどういうものか>` の見出し
- 見出し直後にその技術の一文説明。公式 URL が分かる場合は `<https://...>` で添える
- 「## 特徴」「## 使用に至った背景」「## 主なサブコマンド」「## 導入」など、内容に応じたセクションに整理する
- 重要なキーワードは **太字**、コマンド・ファイル名・識別子はインラインコード、複数行のコマンドやコードは言語指定付きコードブロック
- 前提知識の補足は `> [!NOTE]` の callout で短く入れる
- 元テキストにない事実は追加しない。要約なので冗長な部分は削ってよい
- 出力はマークダウン本文のみ。前置きや説明、コードフェンスでの全体囲みは不要'
if [ -n "$extra" ]; then
  prompt="$prompt

# 追加の指示
$extra"
fi

result=$(printf '%s' "$input" | claude -p "$prompt" --model sonnet)

if [ -z "$result" ]; then
  echo "claude から出力が得られませんでした。"
  exit 1
fi

if [ -z "${NO_PBCOPY:-}" ]; then
  printf '%s\n' "$result" | pbcopy
fi
printf '%s\n' "$result"
