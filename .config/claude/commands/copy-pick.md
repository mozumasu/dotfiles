---
allowed-tools: Bash(~/.config/claude/scripts/copy-answer.sh:*)
argument-hint: "[nth]"
description: 回答内のコードブロック一覧を表示し、番号の返信でコピー
---

対象の AI 回答（引数省略時は最新、数値 N で N 番目前）に含まれるコードブロックの一覧です:

!`~/.config/claude/scripts/copy-answer.sh -l $ARGUMENTS`

一覧はすでにユーザーに表示されている。あなたは「コピーするブロック番号を返信してください（回答全体なら a）」と 1 行だけ案内して停止すること。一覧の再掲・要約はしない。

一覧の取得に失敗した場合（コードブロックなし等）は、そのエラーを 1 行で伝えて停止する。

次のユーザーの返信に応じて、対応するコマンドを実行する（`$ARGUMENTS` はそのまま引き継ぐ）:

- 番号 k → `~/.config/claude/scripts/copy-answer.sh -B <k> $ARGUMENTS`
- `a`（全体）→ `~/.config/claude/scripts/copy-answer.sh $ARGUMENTS`

実行結果を 1 行で報告するだけにしてください。**コピーした本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止のため）。
