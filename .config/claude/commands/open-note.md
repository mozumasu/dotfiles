---
allowed-tools: Bash(~/.config/claude/scripts/open-note.sh:*)
argument-hint: "[-n notebook] [id|filename|title|path]"
description: 保存済みノートを新しいWezTermタブで開く（保存はしない・引数なしで最新ノート）
---

保存済みの nb ノートを新しい WezTerm タブで開きます（保存は行いません）。
`save-answer` / `save-session` の保存と「新タブで開く」を分けて使いたいときに利用します。

- 引数なし: notebook（既定 `log`）内で最も新しいノートを開く。
- nb の id / ファイル名 / タイトル: そのノートを開く（例: `/open-note 42`）。
- ファイルパス: そのファイルを直接開く。
- `-n <notebook>` で対象 notebook を変更可。ビューアは `NB_VIEWER` で変更可（既定: `glow`）。

実行結果:

!`~/.config/claude/scripts/open-note.sh $ARGUMENTS`

上の実行結果を1行で報告するだけにしてください。
