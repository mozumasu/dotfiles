---
allowed-tools: Bash(~/.config/claude/scripts/save-answer.sh:*)
argument-hint: "[-n notebook] [タイトル]"
description: 直前のAI回答をトランスクリプトから抽出してnbに保存（本文は改変なし・ハルシネーション防止）
---

直前のAI回答を、セッションのトランスクリプト(JSONL)から機械抽出して nb に保存します。
本文はスクリプトが JSONL からそのまま書き込むため、モデルによる再生成（ハルシネーション）は発生しません。

- 保存先 notebook は省略時 `log`。`-n <notebook>` で変更可（例: `/save-answer -n home`）。
- タイトルは引数で指定可。省略時は本文の見出し/先頭行から機械生成。

実行結果:

!`~/.config/claude/scripts/save-answer.sh $ARGUMENTS`

上の実行結果を1行で報告するだけにしてください。**保存した本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止が目的のため）。
