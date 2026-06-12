#!/usr/bin/env bash
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Weekly PRs
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 🔀
# @raycast.packageName Calendar
# @raycast.description 今週 (月〜金) に対応した PR 一覧をクリップボードにコピー
#
# Documentation:
# @raycast.author mozumasu
# @raycast.authorURL https://raycast.com/mozumasu

set -euo pipefail

# Raycast の最小 PATH では nix 管理の gh が見えないため明示的に追加する
export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI が見つかりません。home-manager switch を実行してください。"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI 未認証。gh auth login を実行してください。"
  exit 1
fi

# 月曜当日は同日を返すため、これだけで今週の月曜になる
monday=$(date -v -mon +'%Y-%m-%d')
friday=$(date -j -v +4d -f '%Y-%m-%d' "$monday" +'%Y-%m-%d')
range="${monday}..${friday}"

login=$(gh api user --jq '.login')

# 自分が作成し、今週更新のあった PR
authored=$(gh search prs \
  --author=@me \
  --updated="$range" \
  --limit=100 \
  --sort=updated \
  --json title,number,repository,state \
  --jq '.[] | "- [\(.repository.nameWithOwner)#\(.number)] \(.title) (\(.state))"')

# 自分がレビューした他人の PR
reviewed=$(gh search prs \
  --reviewed-by=@me \
  --updated="$range" \
  --limit=100 \
  --sort=updated \
  --json title,number,repository,state,author \
  --jq ".[] | select(.author.login != \"${login}\") | \"- [\(.repository.nameWithOwner)#\(.number)] \(.title) (\(.state))\"")

authored_count=0
[ -n "$authored" ] && authored_count=$(printf '%s\n' "$authored" | wc -l | tr -d ' ')
reviewed_count=0
[ -n "$reviewed" ] && reviewed_count=$(printf '%s\n' "$reviewed" | wc -l | tr -d ' ')
total_count=$((authored_count + reviewed_count))

output="Weekly PRs (${monday} 〜 ${friday}) 合計: ${total_count}件

## 作成した PR (${authored_count}件)
${authored:-なし}

## レビューした PR (${reviewed_count}件)
${reviewed:-なし}"

if [ "${NO_PBCOPY:-}" = "1" ]; then
  printf '%s\n' "$output"
else
  printf '%s' "$output" | pbcopy
  printf '%s\n\n—— クリップボードにコピーしました ——\n' "$output"
fi
