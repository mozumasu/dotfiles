# 手動セットアップ手順

スクリプトを使わずに手動で実行する場合や、各ステップの詳細を理解するための参考。

## 1. プロジェクトタイプを検出する

プロジェクトルートのファイルを確認してプロジェクトタイプを特定する：

- `*.tf` または `.terraform-version` → **Terraform**
- `go.mod` → **Go**
- `package.json` → **Node.js**
- `Cargo.toml` → **Rust**
- `pyproject.toml` または `requirements.txt` → **Python**

`.terraform-version`が存在する場合はバージョン固定のflake.nixを使用する。

## 2. .envrcを作成・更新する

`.envrc`が存在しない場合は作成、存在する場合は`use flake`を追記する：

```text
use flake
```

## 3. flake.nixを生成する

`templates/` ディレクトリから該当するテンプレートをコピーする。
テンプレートが存在しないプロジェクトタイプ（Rust, Python等）の場合は、
既存テンプレートを参考に手動で作成する。

## 4. git addする（重要：direnv allowより先に必ず実行）

Nixはgitで追跡されていないファイルを読み込めないため、**`direnv allow`の前に必ず`git add`を実行する**。
`.envrc`が新規作成の場合も同様にgit addする。

```sh
git add flake.nix .envrc
```

`flake.lock`が生成済みの場合も追加する：

```sh
git add flake.nix .envrc flake.lock
```

## 5. direnv allowを実行する

```sh
direnv allow
```

## 6. 動作確認方法をユーザーに提示する

```sh
# ホームディレクトリに移動してからプロジェクトルートに戻ることでdevShellを確認
cd && cd -
```

## 7. .git/info/excludeを設定するか確認する

direnv allowが完了したら、必ずユーザーに確認する：

> `.git/info/exclude` に `flake.nix`, `flake.lock`, `.envrc` を追加しますか？
> （リポジトリの `.gitignore` を変更せずに、自分のローカル環境でのみ無視できます）

ユーザーが「はい」と答えた場合に設定する：

```text
flake.nix
flake.lock
.envrc
# Nix build outputs
result
result-*
# direnv
.direnv
```
