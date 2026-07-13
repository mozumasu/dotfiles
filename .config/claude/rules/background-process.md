# バックグラウンドプロセスの実行

- **MUST**: バックグラウンドでプロセスを実行するときは Bash ツールの
  `run_in_background` ではなく [ghost](https://github.com/skanehira/ghost) を使う。
- **MUST**: 起動前に `ghost list` で同じコマンドが実行中でないか確認し、多重起動しない。
- **MUST**: シェル演算子でのバックグラウンド化 (`cmd &` / `nohup` / `setsid` / `disown`) も使わない
  (PreToolUse hook が deny する)。

## 使い分け

- **HTTP の dev サーバー**: ghost + [portless](https://github.com/vercel-labs/portless) を組み合わせる。
  portless がポートを自動割り当てし `https://<name>.localhost` で安定してアクセスできる。
  - 起動前の確認: `portless list` で同名ルートがないか確認（名前で多重起動を判定できる）
  - 起動: `ghost run -- portless <name> <command>`
    - 例: `ghost run -- portless myapp pnpm dev`
- **それ以外のバックグラウンドジョブ** (ウォッチャー、ビルド等): ghost 単体で使う。
  - 起動: `ghost run -- <command>`

## ghost の操作

- 一覧: `ghost list`
- ログ確認: `ghost log -f <task_id>`
- 停止: `ghost stop <task_id>`
- **`--` 区切りは必須**: コマンド側にオプションがあると (`--port` 等)、`--` なしでは
  ghost が自分の引数と誤認してエラーになる。常に `ghost run -- <command>` の形で使う。
- **cwd に注意**: ghost はタスク起動時のカレントディレクトリで実行する。
  `pnpm dev` 等は対象 package のディレクトリに `cd` してから `ghost run` する。

## portless の注意点

- **プロキシの生存確認**: マシン再起動後はプロキシ自体が落ちている。アプリ起動前に
  `portless list` がエラーになったら、`ghost run -- portless proxy start --port 1355 --https`
  (sudo 不要版、URL に `:1355` が付く) で復旧する。sudo を使える場合はユーザーに
  `sudo portless proxy start --https` を依頼するとポート表記なしの URL になる。
- **PORT 環境変数を無視するツール**: portless は割り当てポートを `PORT` 環境変数で渡すが、
  無視するツールがある (例: Slidev)。その場合は起動コマンド側で `--port ${PORT:-3030}` の
  ように明示する。
- **IPv6 のみで bind するツールは 502 になる**: portless のプロキシは IPv4 (127.0.0.1) に
  接続するため、`::1` のみで LISTEN するツールはルートがあっても 502 Bad Gateway になる。
  IPv4 bind を強制する (例: Slidev は `--remote --bind 127.0.0.1`)。
- **疎通確認は curl ではなくログで行う**: `ghost log <task_id>` と `portless list` の出力で
  起動・ルート登録を確認する (curl は permission deny 済み)。
