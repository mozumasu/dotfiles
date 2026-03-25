---
name: nix-settings-drift
description: Detect and fix settings.json drift from Nix-managed state. Use when settings.json has been modified outside of Nix (e.g., plugin install, /config changes) and needs to be persisted to the correct source file.
allowed-tools: Read, Bash, Edit, Write, Grep, Glob
---

## 概要

`~/.config/claude/settings.json` が Nix 管理の状態（`.settings.json.nix-managed`）から変更されていないか確認し、差分を適切なソースファイルに反映する。

## 手順

1. `diff <(jq -S . ~/.config/claude/settings.json) <(jq -S . ~/.config/claude/.settings.json.nix-managed)` を実行して差分を確認
2. 差分がなければ「差分なし」と報告して終了
3. 差分がある場合は、以下の振り分けルールに従って適切なファイルに反映

## 振り分けルール

### プライベートマーケットプレイスの判定

`~/.config/claude/.private-marketplaces.json` を読み、`extraKnownMarketplaces` のキー一覧からプライベートマーケットプレイス名を取得する。

### 反映先の判定

| 変更内容 | 反映先 |
|---------|--------|
| プラグイン名の `@` 以降がプライベートマーケットプレイス名と一致する `enabledPlugins` | sops-nix（`user-secrets.yaml` の `claude-private-marketplaces`） |
| `extraKnownMarketplaces` のキーがプライベートマーケットプレイス名と一致 | 同上 |
| 上記以外の `enabledPlugins`、`extraKnownMarketplaces` | `~/dotfiles/.config/nix/home-manager/claude-code.nix` の `publicSettings` |
| `hooks`、`permissions`、`model` 等その他の設定変更 | `claude-code.nix` の `publicSettings` |
| 一時的な変更（`temperature`、`maxTokens` の微調整など） | 無視してよい |

## sops-nix ファイルの編集方法

sops で暗号化されたファイルは直接編集できない。以下のコマンドで編集する:

```bash
sops ~/dotfiles/.config/nix/secrets/user-secrets.yaml
```

`claude-private-marketplaces` キーの値は JSON 文字列。`jq` で整形してから編集内容を確認すること。

## 重要

- `darwin-rebuild switch` の実行はユーザーに任せること（自動実行しない）
- 変更後はユーザーに **何を変更したか** と **`darwin-rebuild switch` の実行が必要** であることを報告すること
