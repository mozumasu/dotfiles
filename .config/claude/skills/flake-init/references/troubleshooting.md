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

## .terraform-version を更新した後に flake が動かなくなった

`.terraform-version` を正として HashiCorp 公式バイナリを直接取得する方式のため、
バージョン更新時は `flake.nix` 内のハッシュ値も更新が必要。

ハッシュの取得方法：

```sh
VERSION=1.14.5  # 新しいバージョンに置き換え
nix-prefetch-url --unpack "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_darwin_arm64.zip"
nix-prefetch-url --unpack "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_darwin_amd64.zip"
nix-prefetch-url --unpack "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"
nix-prefetch-url --unpack "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_arm64.zip"
```

取得したハッシュを `flake.nix` の `terraformPlatform` の各 `hash` フィールドに設定する。
