#!/bin/bash
# Terraformプロバイダーのバージョンが古い場合にClaudeへ修正を促すPostToolUseフック
#
# tfupdate が使える場合: 最新バージョンを取得してファイルを自動更新
# tfupdate がない場合 : Terraform Registry API (curl+jq) で検知してsystemMessageで通知

INPUT=$(cat)
FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")

# .tf ファイル以外はスキップ
[[ "$FILE_PATH" =~ \.tf$ ]] || exit 0
[ -f "$FILE_PATH" ] || exit 0

# required_providers が含まれていなければスキップ
grep -q 'required_providers' "$FILE_PATH" || exit 0

WORK_DIR=$(dirname "$FILE_PATH")
UPDATED=""
OUTDATED=""
CURRENT_SOURCE=""

while IFS= read -r line; do
  # source = "namespace/name" を検出
  if [[ "$line" =~ source[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
    CURRENT_SOURCE="${BASH_REMATCH[1]}"
  fi

  # version = "..." を検出（source が見つかっている場合のみ）
  if [[ -n "$CURRENT_SOURCE" && "$line" =~ version[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
    VERSION_CONSTRAINT="${BASH_REMATCH[1]}"

    if [[ "$VERSION_CONSTRAINT" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
      MIN_MAJOR="${BASH_REMATCH[1]}"
      MIN_MINOR="${BASH_REMATCH[2]}"

      # 最新バージョンを Terraform Registry API で取得
      RESPONSE=$(curl -sf --max-time 5 "https://registry.terraform.io/v1/providers/${CURRENT_SOURCE}" 2>/dev/null)
      LATEST=$(jq -r '.version // empty' <<<"$RESPONSE")

      if [[ -n "$LATEST" && "$LATEST" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        LATEST_MAJOR="${BASH_REMATCH[1]}"
        LATEST_MINOR="${BASH_REMATCH[2]}"

        IS_OUTDATED=false
        if [[ "$LATEST_MAJOR" -gt "$MIN_MAJOR" ]]; then
          IS_OUTDATED=true
        elif [[ "$LATEST_MAJOR" -eq "$MIN_MAJOR" && $((LATEST_MINOR - MIN_MINOR)) -ge 10 ]]; then
          IS_OUTDATED=true
        fi

        if [[ "$IS_OUTDATED" == "true" ]]; then
          PROVIDER_NAME="${CURRENT_SOURCE##*/}"

          if command -v tfupdate &>/dev/null; then
            # tfupdate でファイルを自動更新
            tfupdate provider "$PROVIDER_NAME" --version ">= ${LATEST}" "$WORK_DIR" 2>/dev/null
            UPDATED="${UPDATED}- ${CURRENT_SOURCE}: \`${VERSION_CONSTRAINT}\` → \`>= ${LATEST}\`\n"
          else
            OUTDATED="${OUTDATED}- ${CURRENT_SOURCE}: 制約 \`${VERSION_CONSTRAINT}\` (最新: ${LATEST})\n"
          fi
        fi
      fi
    fi
    CURRENT_SOURCE=""
  fi

  # 閉じ括弧でsourceをリセット
  [[ "$line" =~ ^[[:space:]]*\} ]] && CURRENT_SOURCE=""

done < "$FILE_PATH"

if [[ -n "$UPDATED" ]]; then
  MSG="tfupdate でプロバイダーのバージョン制約を自動更新しました:\n${UPDATED}"
  jq -n --arg msg "$(printf '%b' "$MSG")" '{"systemMessage": $msg}'
elif [[ -n "$OUTDATED" ]]; then
  MSG="以下のTerraformプロバイダーのバージョン制約が古くなっています。最新バージョンに更新してください:\n${OUTDATED}"
  jq -n --arg msg "$(printf '%b' "$MSG")" '{"systemMessage": $msg}'
fi
