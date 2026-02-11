#!/bin/bash

# Karabinerプロファイル自動切り替えスクリプト
# conductorキーボード接続時にJISプロファイルに切り替え

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/auto-switch-profile.log"
KARABINER_CLI="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

US_PROFILE="Mac Built-in (US)"
JIS_PROFILE="External Keyboard (JIS)"
EXTERNAL_KEYBOARD="conductor"

# ログ出力
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 現在のプロファイルを取得
get_current_profile() {
    "$KARABINER_CLI" --show-current-profile-name
}

# プロファイルを切り替え
switch_profile() {
    local profile="$1"
    local current_profile
    current_profile=$(get_current_profile)

    if [ "$current_profile" != "$profile" ]; then
        "$KARABINER_CLI" --select-profile "$profile"
        log "Switched profile: $current_profile -> $profile"
    fi
}

# 外部キーボードが接続されているか確認
is_external_keyboard_connected() {
    system_profiler SPBluetoothDataType 2>/dev/null | \
        grep -A 10 "Connected:" | \
        grep "$EXTERNAL_KEYBOARD" > /dev/null 2>&1
}

# メインループ
main() {
    log "Starting Karabiner profile auto-switcher"

    while true; do
        if is_external_keyboard_connected; then
            switch_profile "$JIS_PROFILE"
        else
            switch_profile "$US_PROFILE"
        fi

        sleep 5  # 5秒ごとにチェック
    done
}

# エラーハンドリング
trap 'log "ERROR: Script terminated"; exit 1' ERR

main
