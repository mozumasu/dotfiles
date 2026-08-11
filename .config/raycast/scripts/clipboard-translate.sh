#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Translate Clipboard
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🌐
# @raycast.packageName Claude
# @raycast.argument1 { "type": "text", "placeholder": "追加の指示 (任意: 訳し方・対象言語など)", "optional": true }
# @raycast.description クリップボードのテキストを claude -p で翻訳し、難しい単語・熟語の解説付きでコピー
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

prompt='以下のテキストを翻訳してください。

# 翻訳ルール
- 日本語のテキストなら英語に、それ以外の言語なら日本語に翻訳する
- 自然で読みやすい訳文にする。技術文書ならソフトウェアエンジニア向けの標準的な訳語を使う
- コードブロック・コマンド・識別子・URL は翻訳せずそのまま残す
- マークダウンの構造 (見出し・箇条書き・引用など) は元のまま保つ

# 出力形式
- まず訳文のみを出力する
- 訳文の後に区切り線 `---` を入れ、`## 単語・熟語` セクションとして、原文に含まれる難しい単語・熟語・イディオム・句動詞を `- **語句**: 意味 (補足があれば簡潔に)` の形式で列挙する
- 中学レベルの基本語は載せず、学習価値のある語句だけを 3〜10 個程度選ぶ。該当がなければセクションごと省略する
- 訳文が英語の場合、単語・熟語の解説は日本語で書く
- 出力は上記のみ。前置きや説明、コードフェンスでの全体囲みは不要'
if [ -n "$extra" ]; then
  prompt="$prompt

# 追加の指示
$extra"
fi

# テキスト変換だけの用途。スキル誤発動やツールによるファイル操作を防ぐ
result=$(printf '%s' "$input" | claude -p "$prompt" --model sonnet --tools "" --disable-slash-commands)

if [ -z "$result" ]; then
  echo "claude から出力が得られませんでした。"
  exit 1
fi

if [ -z "${NO_PBCOPY:-}" ]; then
  printf '%s\n' "$result" | pbcopy
fi
printf '%s\n' "$result"
