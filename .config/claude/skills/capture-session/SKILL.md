---
name: capture-session
description: WezTermペインのバッファをキャプチャして.wezescファイルに保存する。Markdown変換なしの生データ保存のみ
argument-hint: [label]
disable-model-invocation: true
user-invocable: true
allowed-tools: Bash(bash *)
---

# セッションバッファのキャプチャ

`save-session` のステップ1（バッファ取得）のみを実行する軽量版。

## 手順

### 1. capture.sh の実行

```bash
RAW_FILE=$(bash "${CLAUDE_SKILL_DIR}/../save-session/scripts/capture.sh" "$ARGUMENTS")
```

### 2. 結果報告

以下を簡潔に報告:

- 保存先パス（`.wezesc`）
- ファイルサイズ（`ls -lh` で確認）
