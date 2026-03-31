#!/bin/bash
# PreToolUse hook: git commit 実行前にプロジェクトのコミットスタイルを検出し additionalContext で注入

INPUT=$(cat)
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")

# 1. commitlint 設定があればそこから検出
STYLE=""
for cfg in commitlint.config.cjs commitlint.config.mjs commitlint.config.js commitlint.config.ts .commitlintrc .commitlintrc.json .commitlintrc.yaml .commitlintrc.yml; do
  if [ -f "$PROJECT_ROOT/$cfg" ]; then
    if grep -q 'gitmoji\|emoji' "$PROJECT_ROOT/$cfg" 2>/dev/null; then
      STYLE="gitmoji"
    else
      STYLE="conventional"
    fi
    break
  fi
done

# 2. commitlint がなければ git log から推定
RECENT=""
if [ -z "$STYLE" ]; then
  RECENT=$(git log --oneline -10 2>/dev/null || echo "")
  if printf '%s\n' "$RECENT" | perl -CSD -0777 -ne 'exit(/[\x{2728}\x{1F41B}\x{1F4DD}\x{267B}\x{26A1}\x{2705}\x{1F477}\x{1F3A1}\x{1F527}\x{1F484}]/ ? 0 : 1)'; then
    STYLE="gitmoji"
  else
    STYLE="conventional"
  fi
fi

# 3. 言語を git log から推定（日本語文字の有無）
[ -z "$RECENT" ] && RECENT=$(git log --oneline -10 2>/dev/null || echo "")
if printf '%s\n' "$RECENT" | perl -CSD -0777 -ne 'exit(/\p{Hiragana}|\p{Katakana}|\p{Han}/ ? 0 : 1)'; then
  LANG_LABEL="Japanese"
else
  LANG_LABEL="English"
fi

# additionalContext で注入
if [ "$STYLE" = "gitmoji" ]; then
  MSG="Commit style: Conventional Commits + gitmoji ($LANG_LABEL). Format: <type>: <emoji> <description>"
else
  MSG="Commit style: plain Conventional Commits ($LANG_LABEL). Format: <type>: <description> (NO emoji)"
fi

echo "{\"hookSpecificOutput\":{\"additionalContext\":\"$MSG\"}}"
