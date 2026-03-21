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
git status flake.nix .envrc
```

一度ディレクトリを離れて戻ることでdevShellが起動する：

```sh
cd && cd -
```

## .terraform-version のバージョンが nixpkgs と一致しない

`nix flake update` で nixpkgs を更新するか、
`.terraform-version` を nixpkgs が提供するバージョンに合わせる。
エラーメッセージに現在のバージョンと要求バージョンが表示される。
