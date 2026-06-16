---
name: save-session
description: 現在セッションの全会話をトランスクリプト(JSONL)から機械抽出してnbに保存する（本文は改変なし・ハルシネーション防止）。セッションログのアーカイブや振り返りに使用
argument-hint: "[-n notebook] [-o] [label]"
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/scripts/save-session.sh:*)
---

# セッション全体をnbに保存（機械抽出・ハルシネーション防止）

現在セッションの全会話を、セッションのトランスクリプト(JSONL)から機械抽出して nb に保存します。
本文はスクリプトが JSONL からそのまま整形して書き込むため、モデルによる再生成（ハルシネーション）は発生しません。

- 保存先 notebook は省略時 `log`。`-n <notebook>` で変更可。
- `-o` を付けると保存後に新しい WezTerm タブでノートを開く。ビューアは `NB_VIEWER` で変更可（既定: `glow`）。
- 保存パス: `<notebook>:<owner-repo>/<YYYY-MM-DD>-<branch>/sessions/<timestamp>.md`
- タイトル/ファイル名のラベルは引数で指定可。省略時は最初のユーザー入力から機械生成。
- ユーザー入力は `>` 引用、Claudeの応答は本文、tool 呼び出しは `<details>` で折りたたみ（入力/出力が長い場合は truncate）。

実行結果:

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/save-session.sh $ARGUMENTS
```

上の実行結果を1行で報告するだけにしてください。**保存した本文の再掲・要約・補足は一切しないこと**（ハルシネーション防止が目的のため）。
