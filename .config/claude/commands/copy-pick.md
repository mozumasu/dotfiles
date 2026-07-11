---
allowed-tools: Bash(~/.config/claude/scripts/copy-answer.sh:*), AskUserQuestion
argument-hint: "[nth]"
description: 回答内のコードブロックを対話選択してコピー（ビルトイン /copy のピッカー風）
---

対象の AI 回答（引数省略時は最新、数値 N で N 番目前）に含まれるコードブロックの一覧です:

!`~/.config/claude/scripts/copy-answer.sh -l $ARGUMENTS`

上の一覧をもとに、AskUserQuestion でどれをコピーするか選択させてください:

- 選択肢は「各コードブロック」（ラベルは `k) [言語] 先頭行の要約`）と「回答全体」。
- ブロックが 3 個を超える場合は先頭 3 個 + 「回答全体」を選択肢にし、質問文に「他のブロックは Other で番号を入力」と明記する。
- 一覧の取得に失敗した場合（コードブロックなし等）は、「回答全体をコピーするか」だけを確認する。

選択後、対応するコマンドを実行する（`$ARGUMENTS` はそのまま引き継ぐ）:

- ブロック k → `~/.config/claude/scripts/copy-answer.sh -B <k> $ARGUMENTS`
- 回答全体 → `~/.config/claude/scripts/copy-answer.sh $ARGUMENTS`

実行結果を 1 行で報告するだけにしてください。**コピーした本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止のため）。
