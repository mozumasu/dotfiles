# 並列作業の使い分け

並列で作業を進めたいときは、タスクの性質で実行手段を選ぶ:

1. **非対話のバックグラウンドプロセス** (dev サーバー、ウォッチャー、ビルド)
   → ghost (+portless)。[background-process.md](background-process.md) に従う。
2. **進捗を見たい・介入したい並列タスク** (調査、実装、レビューをエージェントに任せる)
   → `HERDR_ENV=1` のとき herdr skill を使ってよい。ペインを split して
   エージェントを起動し、`wait agent-status` → `pane read` で回収する。
3. **見える必要のない使い捨ての調査** (コードリーディング、grep、ドキュメント調査)
   → Agent ツールのサブエージェント。画面を占有しない分こちらが軽い。

## worktree の条件付け

- **編集を伴う並列タスクは worktree を分ける** (`herdr worktree create --branch NAME --base REF`)。
  同一チェックアウトで複数エージェントに編集させると、ブランチ切り替え・未コミット変更の
  混入・index.lock 競合・ビルド成果物の上書きが起きる。
- **読み取り専用の並列タスクは worktree を分けない**。同じチェックアウト共有で問題なく、
  依存インストールやディスクのコストを払う必要がない。
- 作業が終わった worktree は `herdr worktree remove --workspace ID` で片付ける。
- Herdr 外で並列セッションを立てる場合は Claude Code 公式の `claude --worktree <name>` を使う
  (<https://code.claude.com/docs/en/common-workflows.md#run-parallel-sessions-with-worktrees>)。

## worktree ごとの dev サーバー

- 各 worktree のディレクトリに `cd` してから `ghost run -- portless run <command>` で起動する。
  portless は worktree を検出し `https://<worktree>.<project>.localhost` を割り当てるため、
  ポート競合せず worktree ごとに安定した URL が得られる。
- 明示的に名前を付けたい場合は `ghost run -- portless <name> <command>` とし、
  worktree ごとに一意な name (例: `myapp-feature-a`) を使う。
- 起動前の多重起動チェックは `portless list` のルート名と `ghost list` で行う。
