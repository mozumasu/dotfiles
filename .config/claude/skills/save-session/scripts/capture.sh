#!/bin/bash
set -euo pipefail

# WezTermペインのバッファを取得し、mkmdスタイルのパスに保存する
#
# Usage: capture.sh [label]
#
# 環境変数:
#   WEZTERM_PANE  - 取得対象のペインID（WezTermが自動設定）
#
# 出力（stdout）:
#   生成されたファイルのパス（後続処理で利用）

LABEL="${1:-session}"
LOG_BASE="$HOME/src/github.com/mozumasu/nb/log"

# --- git情報の取得 ---
OWNER_REPO=$(git remote get-url origin 2>/dev/null \
  | perl -pe 's{.*[:/]([^/]+)/([^/]+?)(?:\.git)?$}{$1-$2}') \
  || OWNER_REPO="local-$(basename "$PWD")"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "local")
DATE=$(date +%Y-%m-%d)

# --- ディレクトリ作成 ---
BASE_DIR="${LOG_BASE}/${OWNER_REPO}/${DATE}-${BRANCH}/sessions"
mkdir -p "$BASE_DIR"

# --- mktemp でアトミックにファイル生成 ---
RAW_FILE=$(mktemp "${BASE_DIR}/${LABEL}-XXXXXX")
mv "$RAW_FILE" "${RAW_FILE}.md"
RAW_FILE="${RAW_FILE}.md"

# --- ペインバッファの取得 ---
if [[ -z "${WEZTERM_PANE:-}" ]]; then
  echo "Error: WEZTERM_PANE is not set" >&2
  exit 1
fi

wezterm cli get-text --pane-id "$WEZTERM_PANE" --start-line -1000000 > "$RAW_FILE"

# --- 結果をstdoutに出力（後続処理用） ---
echo "$RAW_FILE"
