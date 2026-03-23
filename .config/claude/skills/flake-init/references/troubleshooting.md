# トラブルシューティング

## プロジェクトタイプを検出できない

対応ファイル（`*.tf`, `go.mod`, `package.json`）がプロジェクトルートに存在するか確認する。
サブディレクトリのみにある場合は検出されない。

未対応のプロジェクトタイプ（Rust, Python等）の場合は、
既存テンプレートを参考に `templates/` へ手動でテンプレートを追加する。

## direnv が見つからない

スクリプトは `direnv allow` をスキップして続行する。
direnv インストール後に手動で実行する：

```sh
direnv allow
```

## flake.nix が既に存在する

スクリプトは上書きを確認するプロンプトを表示する。
既存設定を保持したい場合は `N` を選択する。

## direnv allow 後にシェルが変わらない

Nixがgit追跡されていないファイルを読み込めないことが原因の場合が多い。
`flake.nix` と `.envrc` が `git add` されているか確認する：

```sh
git ls-files --error-unmatch flake.nix .envrc
```

追跡されていない場合は `git add -f` で強制追加する：

```sh
git add -f flake.nix .envrc
```

一度ディレクトリを離れて戻ることでdevShellが起動する：

```sh
cd && cd -
```

## .git/info/exclude に追加した後に flake が動かなくなった

`.git/info/exclude` に `flake.nix` を追加すると、`git status` では表示されなくなるが、
既に `git add` 済みのファイルには影響しない。

問題が起きるのは以下の場合：

- `git reset HEAD flake.nix` でアンステージしてしまった
- `.git/info/exclude` 追加後に `git add` せず `git add -f` も実行していない

対処法：

```sh
git add -f flake.nix .envrc
```

**重要**: `.git/info/exclude` は「未追跡ファイルを `git status` に表示しない」だけであり、
`git add -f` で追加したファイルは引き続き追跡される。`git reset HEAD` は絶対に行わないこと。

## .terraform-version のバージョンが nixpkgs と一致しない

`nix flake update` で nixpkgs を更新するか、
`.terraform-version` を nixpkgs が提供するバージョンに合わせる。
エラーメッセージに現在のバージョンと要求バージョンが表示される。
