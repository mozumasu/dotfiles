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
# @raycast.description 指定週 (月〜金) に対応した PR 一覧をクリップボードにコピー
# @raycast.argument1 { "type": "text", "placeholder": "空=今週 / last / 2 (2週前) / 2026-08-24", "optional": true }
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

arg="${1:-}"

case "$arg" in
  ""|this|today|0)
    weeks_ago=0
    ;;
  last)
    weeks_ago=1
    ;;
  [0-9][0-9]-[0-9][0-9])
    base_date="$(date +'%Y')-${arg}"
    ;;
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
    base_date="$arg"
    ;;
  -[0-9]|-[0-9][0-9])
    weeks_ago="${arg#-}"
    ;;
  [0-9]|[0-9][0-9])
    weeks_ago="$arg"
    ;;
  *)
    echo "引数の形式が不正です: $arg"
    echo "使用可能: (空) / this / last / 2 / -2 / 08-24 / 2026-08-24"
    exit 1
    ;;
esac

# 月曜当日は同日を返すため、-v -mon だけでその週の月曜になる
if [ -n "${base_date:-}" ]; then
  if ! monday=$(date -j -v -mon -f '%Y-%m-%d' "$base_date" +'%Y-%m-%d' 2>/dev/null); then
    echo "日付として解釈できません: $arg"
    exit 1
  fi
else
  monday=$(date -j -v -mon -v -"$((weeks_ago * 7))"d +'%Y-%m-%d')
fi
friday=$(date -j -v +4d -f '%Y-%m-%d' "$monday" +'%Y-%m-%d')
range="${monday}..${friday}"

login=$(gh api user --jq '.login')

# 自分が作成し、対象週に更新のあった PR
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
