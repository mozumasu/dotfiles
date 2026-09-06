---
name: pr-slide-screenshots
description: Slidev スライドを変更した PR に、変更スライドのスクリーンショットを PR コメントとして残す。撮影は Playwright MCP、添付は `gh pr comment --attach` (gh 2.99.0 以降) で行う。「スライドの画像を PR に貼って」「表示確認の画像を PR コメントに残して」などのリクエスト、またはスライド変更 PR の作成直後に使用する。
allowed-tools: |
  Bash(gh --version)
  Bash(gh pr view *)
  Bash(gh pr comment *)
  Bash(git diff *)
  Bash(portless list)
  Bash(ghost list)
  Bash(ghost log *)
  Bash(ls -l *)
  Bash(rm slide-*.png)
---

# PR にスライドのスクリーンショットを貼る

Slidev デッキの変更 PR に対して、変更されたスライドのスクリーンショットを撮影し、
`gh pr comment --attach` で PR コメントとして残す。ブラウザで GitHub を操作する必要はない。

## 前提

- `gh --version` が 2.99.0 以上であること (`--attach` フラグは 2.99.0 で追加)。
  古ければ中断してアップグレードを案内する。
- 対象が GitHub.com または GitHub Enterprise Cloud であること (GHES は `--attach` 非対応)
- Playwright MCP で dev サーバーのスライドを撮影できること
- `gh pr view --json number,url` で現在のブランチの PR を特定できること。
  PR がなければ中断して報告する (勝手に PR は作らない)

## 手順

1. **変更スライドの特定**: `git diff origin/main...HEAD --stat -- '*.md'` で変更された
   スライドファイルを確認し、デッキ全体でのスライド番号に変換する。
   番号はエントリ md (`slides.md` 等) の `src:` include 順に、各ファイルのスライド数
   (frontmatter 区切りの数) を数えて算出する。迷ったら dev サーバーの `/overview` を開いて目視確認する。
2. **dev サーバーの確認**: `portless list` / `ghost list` で対象 worktree のサーバーが
   起動済みか確認する。なければ background-process.md の規約どおり、デッキのディレクトリで
   `ghost run -- portless run pnpm dev` で起動し、`ghost log` でポートを確認する。
3. **撮影前のヘルスチェック**: 最初の撮影の前に `browser_tabs` (list) でブラウザ接続の
   疎通を確認する。CDP エラーになったら 1 回だけ再接続を試し、それでも失敗したら
   中断してユーザーに報告する (失敗したまま撮影を繰り返さない)。
4. **撮影**: Playwright MCP で `http://localhost:<port>/<スライド番号>` を開き、
   `browser_take_screenshot` で `slide-<番号>.png` として撮影する (保存先は cwd 直下になる)。
   撮影ごとに `ls -l` でファイルサイズが 0 バイトでないことを確認してから次へ進む
   (0 バイトなら撮り直す)。撮影後は Read ツールで画像を開き、レイアウト崩れ・
   はみ出しがないか確認する (崩れていたら報告し、貼る前に直すかユーザーに判断を仰ぐ)。
5. **本文の作成**: スライド番号ごとの見出しと画像参照を並べた Markdown を書く。
   本文中で `![alt](./slide-N.png)` のようにローカルパスを参照しておくと、
   `--attach` がその参照をアップロード先 URL に書き換える。

   ```markdown
   ## 変更スライドの表示確認

   ### 3 ページ目
   ![slide 3](./slide-3.png)

   ### 5 ページ目
   ![slide 5](./slide-5.png)
   ```

6. **投稿**: 本文をファイルに書き出し、撮影した png を `--attach` で全部渡す
   (フラグは繰り返し指定。1 コマンド最大 50 ファイル)。

   ```sh
   gh pr comment <番号> --body-file comment.md \
     --attach './slide-3.png#slide 3' --attach './slide-5.png#slide 5'
   ```

   本文で参照していないファイルはコメント末尾に追記される。alt text は
   `<path>#<alt>` の形式で指定でき、本文側に alt があればそちらが優先される。
7. **投稿確認**: `gh pr view <番号> --json comments --jq '.comments[-1].body'` で
   画像参照が `github.com/user-attachments/assets/...` の URL に置き換わっていることを確認してから完了報告する。
8. **後片付け**: 撮影した png と `comment.md` を削除する (リポジトリにはコミットしない)。

## 注意

- 画像の実体は `github.com/user-attachments/assets/...` にホストされ、可視性は
  リポジトリに従う (private リポジトリなら画像も private)。
- `--attach` は `gh pr create` / `gh pr edit` / `gh issue comment` でも使える。
  PR 作成時に貼りたい場合は `gh pr create --attach ...` で本文に直接入れてよい。
- ユーザーがブラウザを操作中のことがある。撮影で開いたタブだけを操作し、
  終わったら `browser_tabs` の `close` で閉じる。
