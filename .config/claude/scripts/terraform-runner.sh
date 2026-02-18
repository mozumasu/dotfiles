#!/bin/bash
# Claude Code PreToolUse hook for Terraform command routing
# Detects Docker execution environment from project root files:
#   - compose.yaml / compose.yml present → Docker
#   - neither → local

input=$(</dev/stdin)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# terraform/terragrunt コマンドでなければスキップ（cd付きも対応）
echo "$command" | grep -qE '\b(terraform|terragrunt)\b' || exit 0

# すでに docker compose exec 経由であればスキップ（二重インターセプト防止）
echo "$command" | grep -qE '\bdocker\s+compose\b.*\bexec\b' && exit 0

# コマンド内の cd 先ディレクトリを抽出、なければ PWD を使用
work_dir=$(echo "$command" | perl -ne 'print $1 if /(?:^|&&)\s*cd\s+(\S+)/' | tail -1)
[ -z "$work_dir" ] && work_dir="$PWD"

# git リポジトリルートを取得（cd先で評価）
project_root=$(git -C "$work_dir" rev-parse --show-toplevel 2>/dev/null)

# git リポジトリ外であればスキップ
[ -z "$project_root" ] && exit 0

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

# compose.yaml からプロジェクトルートのコンテナ内マウントパスを取得
container_base=$(docker compose -f "${compose_file}" config --format json 2>/dev/null \
  | jq -r --arg src "$project_root" --arg svc "$service" \
    '.services[$svc].volumes[]? | select(.source == $src) | .target' \
  | head -1)
[ -z "$container_base" ] && container_base="/workspace"

# ローカルパスからコンテナ内パスを計算
rel_path="${work_dir#${project_root}}"
rel_path="${rel_path#/}"
container_dir="${container_base}${rel_path:+/${rel_path}}"

# コマンドから terraform/terragrunt 以降の部分だけ抽出
tf_command=$(echo "$command" | perl -ne 'print $1 if /\b((terraform|terragrunt)\s+.+?)(?:\s*2>&1)?\s*$/')

# コンテナ起動確認
container_running=$(docker compose -f "${compose_file}" ps --status running --services 2>/dev/null | grep -c "^${service}$")

if [ "$container_running" -eq 0 ]; then
  jq -n \
    --arg reason "[terraform-runner] Docker service \"${service}\" is not running. Run \`docker compose -f ${project_root}/${compose_filename} up -d ${service}\` first, then retry." \
    '{"decision": "block", "reason": $reason}'
  exit 2
fi

jq -n \
  --arg reason "[terraform-runner] This project runs terraform inside Docker. Run this instead:
docker compose -f ${project_root}/${compose_filename} exec ${service} sh -c \"cd ${container_dir} && ${tf_command}\"" \
  '{"decision": "block", "reason": $reason}'
exit 2
