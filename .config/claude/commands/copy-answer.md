---
allowed-tools: Bash(~/.config/claude/scripts/copy-answer.sh:*)
argument-hint: "[-c count] [-t]"
description: 直前のAI回答をトランスクリプトから抽出してクリップボードにコピー（本文は改変なし・ハルシネーション防止）
---

直前のAI回答を、セッションのトランスクリプト(JSONL)から機械抽出して macOS のクリップボード (`pbcopy`) にコピーします。
本文はスクリプトが JSONL からそのまま流すため、モデルによる再生成（ハルシネーション）は発生しません。

- 省略時は直近 1 件の本文のみコピー。
- `-c <count>` で直近 count 件を時系列順（古い→新しい）で `---` 区切り結合（例: `/copy-answer -c 3`）。
- `-t` を付けると先頭にタイトル行（`# <title> - <日時>`）を付与。

実行結果:

!`~/.config/claude/scripts/copy-answer.sh $ARGUMENTS`

上の実行結果を1行で報告するだけにしてください。**コピーした本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止が目的のため）。
