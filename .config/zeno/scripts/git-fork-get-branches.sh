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
  git ${1:+-C "$1"} branch -r --sort=-committerdate --format='%(refname:short)' \
    | perl -ne 'next if m{^[^/]+$}; s|^[^/]+/||; next if /^HEAD$/; print unless $seen{$_}++'
}

# OWNER/REPO from a local clone's upstream (fallback: origin) remote
repo_from_remote() {
  { git ${1:+-C "$1"} remote get-url upstream 2>/dev/null \
    || git ${1:+-C "$1"} remote get-url origin 2>/dev/null \
    || true; } \
    | perl -ne 's|.*github\.com[:/]||; s|\.git$||; chomp; print'
}

# Open PR head branches as "owner:branch" (third-party forks only;
# same-repo heads already appear in the plain branch list)
list_pr_head_branches() {
  local target="${1:-}"
  [ -z "$target" ] && return 0
  gh pr list -R "$target" --state open --limit 100 \
    --json headRefName,headRepositoryOwner \
    --jq '.[] | "\(.headRepositoryOwner.login):\(.headRefName)"' 2>/dev/null \
    | grep -iv "^${target%%/*}:" || true
}

if [ -z "$repo" ]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git fetch --all --quiet 2>/dev/null
    list_remote_branches
    list_pr_head_branches "$(repo_from_remote)"
  fi
  exit 0
fi

local_path="$(ghq root 2>/dev/null)/github.com/$repo"

if [ -d "$local_path/.git" ]; then
  git -C "$local_path" fetch --all --quiet 2>/dev/null
  list_remote_branches "$local_path"
  list_pr_head_branches "$(repo_from_remote "$local_path")"
else
  gh api graphql -f owner="${repo%%/*}" -f name="${repo##*/}" -f query='
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        refs(refPrefix: "refs/heads/", first: 100, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
          nodes { name }
        }
      }
    }' -q '.data.repository.refs.nodes[].name' 2>/dev/null
  list_pr_head_branches "$repo"
fi
