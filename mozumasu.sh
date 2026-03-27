#!/usr/bin/env bash
set -euo pipefail

IMAGE="${1:-./image.png}"
TEXT="${2:-Hey}"

IMG_W=30
IMG_H=12
GAP=2
FONT="slant"
V_ALIGN="bottom" # top|center|bottom

mapfile -t LINES < <(figlet -f "$FONT" -w 200 "$TEXT")
TEXT_H="${#LINES[@]}"

case "$V_ALIGN" in
top) PAD=0 ;;
bottom) PAD=$((IMG_H > TEXT_H ? IMG_H - TEXT_H : 0)) ;;
center) PAD=$((IMG_H > TEXT_H ? (IMG_H - TEXT_H) / 2 : 0)) ;;
*) PAD=0 ;;
esac

printf '\033[2J\033[H'

# (0,0) に画像を置く 位置指定は 0 起点
wezterm imgcat --position 0,0 --width "$IMG_W" --height "$IMG_H" "$IMAGE"

START_COL=$((IMG_W + GAP + 1))
START_ROW=$((1 + PAD))

# wezterm imgcat が出力する余計な数値をクリア（画像右側のテキスト領域のみ）
for ((r=1; r<=IMG_H; r++)); do
  printf '\033[%d;%dH\033[K' "$r" "$START_COL"
done

# TrueColor 例: シアン
printf '\033[38;2;0;220;255m'
for i in "${!LINES[@]}"; do
  row=$((START_ROW + i))
  printf '\033[%d;%dH%s' "$row" "$START_COL" "${LINES[$i]}"
done
printf '\033[0m'
printf '\033[%d;1H' $((IMG_H + 2))
