#!/bin/bash
set -e

DATE=$(date +%Y-%m-%d)
REPORT_DIR=~/src/reports
REPORT_FILE="$REPORT_DIR/$DATE.md"
TEMPLATE=~/dotfiles/docs/templates/daily.md

mkdir -p "$REPORT_DIR"

# ファイルがなければテンプレからコピー
if [ ! -f "$REPORT_FILE" ]; then
  cp "$TEMPLATE" "$REPORT_FILE"
  sed -i '' "s/{{YYYY-MM-DD}}/$DATE/" "$REPORT_FILE" # macOS 用（BSD sed）
fi
echo "which nvim = $(which nvim)" >>/tmp/report.log

/opt/homebrew/bin/nvim "$REPORT_FILE"
