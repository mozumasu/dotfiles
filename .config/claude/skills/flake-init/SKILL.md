---
name: flake-init
description: >
  プロジェクトタイプを自動検出し、flake.nix・.envrc・direnv環境を一括生成する。
  Terraform、Go、Node.jsに対応し、.terraform-versionによるバージョン固定もサポート。
  「flake.nixを作って」「Nix環境をセットアップして」「devShellを追加して」「nix環境が欲しい」
  「direnv設定して」「開発環境をNixで管理したい」などのリクエスト、
  または /flake-init コマンドで発動する。
---

# flake-init: Nix flake環境セットアップ

プロジェクトタイプを自動検出し、`flake.nix` + `.envrc` + `direnv allow` を一括セットアップする。

## 前提条件

- Gitリポジトリ内であること（必須）
- `direnv` がインストールされていること（未インストールの場合は `direnv allow` をスキップ）

## 使い方

`scripts/flake-init.sh` を実行する。

```sh
bash scripts/flake-init.sh [project_dir]
```

### 自動検出ルール

| ファイル | プロジェクトタイプ | テンプレート |
|---------|-------------------|-------------|
| `*.tf` | Terraform | `templates/terraform.nix` |
| `.terraform-version` | Terraform (バージョン固定) | `templates/terraform-version-pinned.nix` |
| `go.mod` | Go | `templates/go.nix` |
| `package.json` | Node.js | `templates/nodejs.nix` |

### スクリプトが行うこと

1. `.envrc` の作成・更新（`use flake` の追記）
2. プロジェクトタイプに応じた `flake.nix` を `templates/` からコピー
3. `git add flake.nix .envrc`
4. `direnv allow` の実行
5. `.git/info/exclude` の設定（対話的に確認）

### 新しいプロジェクトタイプの追加

`templates/` にテンプレートを追加し、`scripts/flake-init.sh` の `detect_project_type` に分岐を足す。

手動で実行する場合は `references/manual-steps.md`、
問題が発生した場合は `references/troubleshooting.md` を参照。
