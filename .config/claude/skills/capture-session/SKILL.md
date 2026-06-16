---
name: capture-session
description: WezTermペインのバッファをANSIカラー付きで.wezescファイルにキャプチャする単体ツール。Markdown変換なしの生データ保存のみ
argument-hint: [label]
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash(bash *)
---

# セッションバッファのキャプチャ

WezTermペインのバッファを `--escapes`（ANSIカラー付き）で取得し、`.wezesc` ファイルに生のまま保存する単体ツール。
Markdown変換はせず、後から `nvim` 等でカラー付きのまま振り返る用途に使う。

（会話内容を整形して残したい場合は、トランスクリプト(JSONL)から機械抽出する `save-session` を使う。こちらは WezTerm に依存しない別系統。）

## 手順

### 1. capture.sh の実行

```bash
RAW_FILE=$(bash "${CLAUDE_SKILL_DIR}/../save-session/scripts/capture.sh" "$ARGUMENTS")
```

### 2. 結果報告

以下を簡潔に報告:

- 保存先パス（`.wezesc`）
- ファイルサイズ（`ls -lh` で確認）
