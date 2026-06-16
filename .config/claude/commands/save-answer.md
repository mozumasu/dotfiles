---
allowed-tools: Bash(~/.config/claude/scripts/save-answer.sh:*)
argument-hint: "[-n notebook] [-c count] [-o] [タイトル]"
description: 直前のAI回答をトランスクリプトから抽出してnbに保存（本文は改変なし・ハルシネーション防止）
---

直前のAI回答を、セッションのトランスクリプト(JSONL)から機械抽出して nb に保存します。
本文はスクリプトが JSONL からそのまま書き込むため、モデルによる再生成（ハルシネーション）は発生しません。

- 保存先 notebook は省略時 `log`。`-n <notebook>` で変更可（例: `/save-answer -n home`）。
- 保存する回答件数は省略時 `1`。`-c <count>` で直近いくつの回答を保存するか指定可（例: `/save-answer -c 3`）。2 以上なら直近 count 件を時系列順（古い→新しい）で 1 つのノートに `---` 区切りで保存。
- `-o` を付けると保存後に新しい WezTerm タブでノートを開く（例: `/save-answer -o`）。ビューアは `NB_VIEWER` で変更可（既定: `glow`）。
- タイトルは引数で指定可。省略時は本文（最新回答）の見出し/先頭行から機械生成（複数件時は「（直近N件）」を付与）。

実行結果:

!`~/.config/claude/scripts/save-answer.sh $ARGUMENTS`

上の実行結果を1行で報告するだけにしてください。**保存した本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止が目的のため）。
