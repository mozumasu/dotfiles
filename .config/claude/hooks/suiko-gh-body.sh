#!/bin/bash
# PreToolUse: gh で issue / PR の本文を投稿する前に suiko で日本語を lint する。
#
# 本文の渡し方は 3 通りあり、Claude が使うのはほぼ heredoc。
#   --body "$(cat <<'EOF' ... EOF)" / --body-file <path> / --body '<text>'

set -u

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
[ -z "$COMMAND" ] && exit 0

BODY=$(perl -0777 -ne '
  # heredoc 本体。終端子は EOF に限らない
  if (/<<-?\s*["\x27]?(\w+)["\x27]?\r?\n(.*?)\r?\n\s*\1\b/s) { print $2; exit }
  # --body-file / -F はパスを指す
  if (/(?:--body-file|-F)[ =]+(\S+)/) {
    my $p = $1; $p =~ s/^["\x27]|["\x27]$//g;
    if (open my $fh, "<", $p) { local $/; print <$fh>; }
    exit;
  }
  if (/(?:--body|-b)[ =]+\x27([^\x27]*)\x27/s) { print $1; exit }
  if (/(?:--body|-b)[ =]+"([^"]*)"/s)          { print $1; exit }
' <<<"$COMMAND")

[ -z "${BODY// /}" ] && exit 0

case "$COMMAND" in
  *"issue create"*)  LABEL="issue 本文" ;;
  *"pr create"*)     LABEL="PR 本文" ;;
  *"issue comment"*) LABEL="issue コメント" ;;
  *"pr comment"*)    LABEL="PR コメント" ;;
  *)                 LABEL="GitHub への投稿本文" ;;
esac

printf '%s' "$BODY" | ~/.config/claude/hooks/suiko-lint.sh - tech info "$LABEL"
