#!/bin/bash
# Claude Code PreToolUse hook for Terraform command routing
# Detects Docker execution environment from project root files:
#   - compose.yaml / compose.yml present → Docker
#   - flake.nix present → local (no Docker)
#   - neither → local

input=$(</dev/stdin)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# terraform/terragrunt コマンドでなければスキップ
echo "$command" | grep -qE '^\s*(terraform|terragrunt)\s+' || exit 0

# git リポジトリルートを取得
project_root=$(git rev-parse --show-toplevel 2>/dev/null)

# git リポジトリ外であればスキップ
[ -z "$project_root" ] && exit 0

# flake.nix があればローカル実行（Docker不使用）
[ -f "${project_root}/flake.nix" ] && exit 0

# compose ファイルを確認
compose_file=""
if [ -f "${project_root}/compose.yaml" ]; then
  compose_file="${project_root}/compose.yaml"
elif [ -f "${project_root}/compose.yml" ]; then
  compose_file="${project_root}/compose.yml"
fi

# compose ファイルなし → ローカル実行
[ -z "$compose_file" ] && exit 0

compose_filename=$(basename "$compose_file")

# terraform/terragrunt を含むサービス名を検出（python3でYAMLパース）
service=$(python3 -c "
import yaml, sys
with open('$compose_file') as f:
    data = yaml.safe_load(f)
services = data.get('services', {})
for name in services:
    if 'terraform' in name or 'terragrunt' in name:
        print(name)
        break
" 2>/dev/null)

# サービスが見つからなければデフォルト
service="${service:-terraform}"

# コンテナ起動確認
container_running=$(docker compose -f "${compose_file}" ps --status running --services 2>/dev/null | grep -c "^${service}$")

if [ "$container_running" -eq 0 ]; then
  printf '{"systemMessage": "[terraform-runner] WARNING: Docker service \"%s\" is not running. Run `docker compose up -d %s` first."}' \
    "$service" "$service"
  exit 0
fi

printf '{"systemMessage": "[terraform-runner] This project runs terraform inside Docker. Execute as: docker compose -f %s exec %s sh -c \"cd /workspace && %s\""}' \
  "${project_root}/${compose_filename}" "$service" "$command"
