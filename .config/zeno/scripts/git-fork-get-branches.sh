#!/usr/bin/env bash
set -euo pipefail

cmdline="${1:-}"

# Extract owner/repo from command line (normalize URLs)
repo=$(echo "$cmdline" | perl -ne '
  s|https?://github\.com/||; s|git\@github\.com:||; s|\.git\b||;
  # skip flags and their values
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

list_remote_branches() {
  git ${1:+-C "$1"} branch -r --format='%(refname:short)' \
    | perl -ne 'next if m{^[^/]+$}; s|^[^/]+/||; next if /^HEAD$/; print' \
    | sort -u
}

if [ -z "$repo" ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git fetch --all --quiet 2>/dev/null
    list_remote_branches
  fi
  exit 0
fi

local_path="$(ghq root 2>/dev/null)/github.com/$repo"

if [ -d "$local_path/.git" ]; then
  git -C "$local_path" fetch --all --quiet 2>/dev/null
  list_remote_branches "$local_path"
else
  gh api "repos/$repo/branches" --paginate -q '.[].name' 2>/dev/null
fi
