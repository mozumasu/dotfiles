#!/usr/bin/env bash
set -euo pipefail

branch="${1:-}"
cmdline="${2:-}"

[ -z "$branch" ] && exit 0

repo=$(echo "$cmdline" | perl -ne '
  s|https?://github\.com/||; s|git\@github\.com:||; s|\.git\b||;
  my @tokens = split /\s+/;
  for my $t (@tokens) {
    next if $t =~ /^-/;
    next if $t eq "git-fork-get";
    if ($t =~ m{^([\w.-]+/[\w.-]+)$}) {
      print $1;
      last;
    }
  }
')

show_local_log() {
  local dir="${1:-.}"
  local remote
  for remote in upstream origin; do
    if git -C "$dir" show-ref --verify --quiet "refs/remotes/$remote/$branch" 2>/dev/null; then
      git -C "$dir" log "$remote/$branch" --oneline --format="%C(yellow)%h %C(green)%ad %C(blue)%an%C(reset) %s" --date=short -10
      return
    fi
  done
  echo "Branch '$branch' not found in remotes"
}

if [ -z "$repo" ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    show_local_log
  fi
  exit 0
fi

local_path="$(ghq root 2>/dev/null)/github.com/$repo"

if [ -d "$local_path/.git" ]; then
  show_local_log "$local_path"
else
  gh api "repos/$repo/commits?sha=$branch&per_page=10" \
    -q '.[] | "\(.sha[0:7]) \(.commit.author.date[0:10]) \(.commit.author.name) \(.commit.message | split("\n")[0])"' \
    2>/dev/null || echo "Failed to fetch commits"
fi
