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

# 3. 言語を git log の subject と body で別々に推定
SUBJECTS=$(git log --format=%s -10 2>/dev/null || echo "")

# subject: 過半数が日本語かどうかで判定
JA_SUBJECT_RATIO=$(printf '%s\n' "$SUBJECTS" | perl -CSD -ne '
  $total++ if /\S/;
  $ja++ if /\p{Hiragana}|\p{Katakana}|\p{Han}/;
  END { printf "%.0f", ($total ? $ja / $total * 100 : 0) }
')
HAS_JA_SUBJECT=false
[ "$JA_SUBJECT_RATIO" -gt 50 ] && HAS_JA_SUBJECT=true

# body: NUL 区切りで commit ごとに分割し、非空 body のうち過半数が日本語を含めば日本語と判定
# （単発の日本語混入で fully-English のリポジトリが誤判定されないようにする）
HAS_JA_BODY=$(git log -z --format=%b -10 2>/dev/null | perl -CSD -0 -ne '
  $non_empty++ if /\S/;
  $ja++ if /\S/ && /\p{Hiragana}|\p{Katakana}|\p{Han}/;
  END {
    if ($non_empty && $ja * 100 / $non_empty > 50) {
      print "true"
    } else {
      print "false"
    }
  }
')
[ -z "$HAS_JA_BODY" ] && HAS_JA_BODY=false

if ! $HAS_JA_SUBJECT && $HAS_JA_BODY; then
  LANG_LABEL="English subject, Japanese body"
elif $HAS_JA_SUBJECT; then
  LANG_LABEL="Japanese"
else
  LANG_LABEL="English"
fi

# 4. scope 使用率を推定（`fix(ui):` のようなパターン）
SCOPE_RATIO=$(printf '%s\n' "$SUBJECTS" | perl -ne '
  $total++ if /\S/;
  $scoped++ if /^\w+\([^)]+\)!?:/;
  END { printf "%.0f", ($total ? $scoped / $total * 100 : 0) }
')
USES_SCOPE=false
[ "$SCOPE_RATIO" -gt 50 ] && USES_SCOPE=true

# 5. フォーマット文字列を組み立て
if [ "$STYLE" = "gitmoji" ]; then
  STYLE_LABEL="Conventional Commits + gitmoji"
  if $USES_SCOPE; then
    FORMAT="<type>(<scope>): <emoji> <description>"
  else
    FORMAT="<type>: <emoji> <description>"
  fi
else
  STYLE_LABEL="plain Conventional Commits (NO emoji)"
  if $USES_SCOPE; then
    FORMAT="<type>(<scope>): <description>"
  else
    FORMAT="<type>: <description>"
  fi
fi

# 6. 直近 3 件の subject を例として添える（検出ルールでは拾えないニュアンスを伝える）
EXAMPLES=$(printf '%s\n' "$SUBJECTS" | grep -v '^[[:space:]]*$' | head -3 | perl -pe 's/^/- /')

MSG="Commit style: $STYLE_LABEL ($LANG_LABEL). Format: $FORMAT
Recent examples (mirror this style):
$EXAMPLES"

# additionalContext で注入（jq で安全に JSON 化）
jq -n --arg ctx "$MSG" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
