#!/bin/bash
# PreToolUse (Bash): シェル演算子でのバックグラウンド化を deny する。
# run_in_background:true は permissions の deny ルールが塞ぐが、
# パラメータマッチは `cmd &` / nohup / setsid / disown には届かないため
# コマンド文字列側をここで検査する。

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

[ -z "$COMMAND" ] && exit 0

# クォート内の & (URL やコミットメッセージ等) は除外してから、
# 制御演算子としての単独 & (&& / |& / >& / <& は除く) と
# nohup / setsid / disown のコマンド位置での使用を検出する
if perl -e '
  my $c = $ARGV[0];
  $c =~ s/\x27[^\x27]*\x27//g;
  $c =~ s/"[^"]*"//g;
  exit 0 if $c =~ /(^|[^&>|<])&(?!&)/;
  exit 0 if $c =~ /(^|[;&|(]\s*)(nohup|setsid|disown)\b/;
  exit 1;
' "$COMMAND"; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "シェルでのバックグラウンド化 (& / nohup / setsid) は禁止。ghost list で多重起動を確認してから ghost run <command> を使うこと (HTTP dev サーバーは ghost run portless <name> <command>)。詳細: rules/background-process.md"
    }
  }'
fi

exit 0
