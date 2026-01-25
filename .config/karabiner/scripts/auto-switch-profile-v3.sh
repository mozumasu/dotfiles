#!/bin/bash

# Karabinerプロファイル自動切り替えスクリプト v3 (イベント駆動型・修正版)
# Bluetooth接続イベントをリアルタイム監視して即座にプロファイルを切り替え

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KARABINER_JSON="$HOME/.config/karabiner/karabiner.json"
DEVICE_CONFIG="$SCRIPT_DIR/device-config.json"
LOCK_FILE="$SCRIPT_DIR/.switch.lock"
LOG_FILE="$SCRIPT_DIR/auto-switch-profile.log"

# ログ出力関数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# エラーハンドリング
trap 'log "ERROR: Script terminated unexpectedly"' ERR

# 設定ファイル読み込み
if [ ! -f "$DEVICE_CONFIG" ]; then
    log "ERROR: Device config not found: $DEVICE_CONFIG"
    exit 1
fi

# デフォルトプロファイルを取得
DEFAULT_PROFILE=$(jq -r '.default_profile' "$DEVICE_CONFIG")

# 接続中のBluetoothデバイスを取得（実際に接続されているもののみ）
get_connected_devices() {
    system_profiler SPBluetoothDataType 2>/dev/null | \
        perl -0777 -ne '
            # Not Connected: より前の部分（接続中のデバイス）を取得
            my $text = $_;
            my $not_connected_pos = index($text, "Not Connected:");

            my $connected_section;
            if ($not_connected_pos >= 0) {
                $connected_section = substr($text, 0, $not_connected_pos);
            } else {
                $connected_section = $text;
            }

            # 接続中のデバイスを抽出（Bluetooth Controller以外）
            while ($connected_section =~ /^\s{10}([^:]+):\s*\n(?:\s+.*\n)*?\s+Vendor ID:\s+(0x[0-9A-Fa-f]+)\s*\n(?:\s+.*\n)*?\s+Product ID:\s+(0x[0-9A-Fa-f]+)/gm) {
                my ($name, $vid, $pid) = ($1, $2, $3);
                $name =~ s/^\s+|\s+$//g;
                # Bluetooth Controllerを除外
                next if $name =~ /Bluetooth Controller/i;
                print "$name|$vid|$pid\n";
            }
        '
}

# デバイスに対応するプロファイルを取得
get_profile_for_device() {
    local device_info="$1"
    local name=$(echo "$device_info" | cut -d'|' -f1)
    local vid=$(echo "$device_info" | cut -d'|' -f2)
    local pid=$(echo "$device_info" | cut -d'|' -f3)

    jq -r --arg vid "$vid" --arg pid "$pid" \
        '.devices[] | select(.vendor_id == $vid and .product_id == $pid) | .profile' \
        "$DEVICE_CONFIG" 2>/dev/null || echo ""
}

# 現在選択されているプロファイルを取得
get_current_profile() {
    jq -r '.profiles[] | select(.selected == true) | .name' "$KARABINER_JSON" 2>/dev/null || echo ""
}

# プロファイルを切り替え（ロック機構付き）
switch_profile() {
    local target_profile="$1"

    # ロックディレクトリで同時実行を防止（macOS互換）
    if ! mkdir "$LOCK_FILE" 2>/dev/null; then
        return 1
    fi

    # トラップでロック解放を保証
    trap "rmdir '$LOCK_FILE' 2>/dev/null || true" EXIT

    local current_profile
    current_profile=$(get_current_profile)

    if [ "$current_profile" = "$target_profile" ]; then
        rmdir "$LOCK_FILE" 2>/dev/null || true
        return 0
    fi

    log "Switching profile: $current_profile -> $target_profile"

    # プロファイルのインデックスを取得
    local profile_index
    profile_index=$(jq --arg name "$target_profile" \
        '[.profiles[].name] | index($name)' "$KARABINER_JSON")

    if [ "$profile_index" = "null" ]; then
        log "ERROR: Profile not found: $target_profile"
        rmdir "$LOCK_FILE" 2>/dev/null || true
        return 1
    fi

    # すべてのプロファイルのselectedをfalseに
    local updated_json
    updated_json=$(jq '.profiles[].selected = false' "$KARABINER_JSON")

    # 対象プロファイルのselectedをtrueに
    updated_json=$(echo "$updated_json" | jq ".profiles[$profile_index].selected = true")

    # 一時ファイルに書き込んで、アトミックに置き換え
    local temp_file
    temp_file=$(mktemp)
    echo "$updated_json" > "$temp_file"
    mv "$temp_file" "$KARABINER_JSON"

    # Karabinerに設定再読み込みを通知
    launchctl kickstart -k "gui/$(id -u)/org.pqrs.karabiner.karabiner_console_user_server" 2>/dev/null || true

    log "✓ Profile switched to: $target_profile"

    rmdir "$LOCK_FILE" 2>/dev/null || true
}

# 最適なプロファイルを決定
determine_profile() {
    local connected_devices
    connected_devices=$(get_connected_devices)

    if [ -z "$connected_devices" ]; then
        echo "$DEFAULT_PROFILE"
        return
    fi

    # 優先度順（設定ファイルの順序）で最初にマッチしたデバイスのプロファイルを使用
    while IFS= read -r device; do
        local profile
        profile=$(get_profile_for_device "$device")
        if [ -n "$profile" ]; then
            echo "$profile"
            return
        fi
    done <<< "$connected_devices"

    # マッチしなければデフォルト
    echo "$DEFAULT_PROFILE"
}

# 初回起動時：現在の接続状態を確認してプロファイル設定
initial_setup() {
    log "=== Initial setup ==="
    local target_profile
    target_profile=$(determine_profile)
    log "Detected profile: $target_profile"
    switch_profile "$target_profile"
}

# イベント監視モード
monitor_mode() {
    log "=== Starting event monitor mode (improved) ==="
    log "Monitoring Bluetooth connection events..."

    # 設定ファイルから監視するデバイス名を取得
    local device_names
    device_names=$(jq -r '.devices[].name' "$DEVICE_CONFIG" | tr '\n' '|' | sed 's/|$//')

    # デバウンス用の一時ファイル
    local debounce_file="$SCRIPT_DIR/.last_process_time"
    echo "0" > "$debounce_file"

    # log streamでBluetooth接続イベントを監視
    # Device found (接続) と DeleteDevice (切断) を検出
    /usr/bin/log stream \
        --predicate 'subsystem == "com.apple.bluetooth" AND (eventMessage CONTAINS "Device found" OR eventMessage CONTAINS "DeleteDevice")' \
        --level info \
        --style compact 2>/dev/null | \
        while IFS= read -r line; do
            # 監視対象デバイスのイベントのみ処理
            if echo "$line" | grep -qE "$device_names"; then
                # デバウンス: 直前の処理から2秒以内は無視
                local current_time
                current_time=$(date +%s)
                local last_process_time
                last_process_time=$(cat "$debounce_file" 2>/dev/null || echo "0")
                local time_diff=$((current_time - last_process_time))

                if [ $time_diff -lt 2 ]; then
                    continue
                fi

                echo "$current_time" > "$debounce_file"

                log "Bluetooth event detected for monitored device"
                local target_profile
                target_profile=$(determine_profile)
                switch_profile "$target_profile" || true
            fi
        done
}

# メイン処理
main() {
    case "${1:-monitor}" in
        initial)
            initial_setup
            ;;
        monitor)
            initial_setup
            monitor_mode
            ;;
        check)
            # 手動チェック用
            local target_profile
            target_profile=$(determine_profile)
            log "Manual check - Target profile: $target_profile"
            switch_profile "$target_profile"
            ;;
        *)
            log "Usage: $0 {initial|monitor|check}"
            exit 1
            ;;
    esac
}

main "$@"
