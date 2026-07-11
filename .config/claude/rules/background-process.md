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
  - 起動: `ghost run portless <name> <command>`
    - 例: `ghost run portless myapp pnpm dev`
- **それ以外のバックグラウンドジョブ** (ウォッチャー、ビルド等): ghost 単体で使う。
  - 起動: `ghost run <command>`

## ghost の操作

- 一覧: `ghost list`
- ログ確認: `ghost log -f <task_id>`
- 停止: `ghost stop <task_id>`
