---
name: pr-slide-screenshots
description: Slidev スライドを変更した PR に、変更スライドのスクリーンショットを PR コメントとして残す。Playwright MCP でログイン済みブラウザから GitHub の Web UI に画像を添付する (トークン不要)。「スライドの画像を PR に貼って」「表示確認の画像を PR コメントに残して」などのリクエスト、またはスライド変更 PR の作成直後に使用する。
allowed-tools: |
  Bash(gh pr view *)
  Bash(git diff *)
  Bash(portless list)
  Bash(ghost list)
  Bash(ghost log *)
---

# PR にスライドのスクリーンショットを貼る

Slidev デッキの変更 PR に対して、変更されたスライドのスクリーンショットを撮影し、
**Playwright MCP (ログイン済みブラウザに CDP 接続) で GitHub Web UI から画像を添付**して
PR コメントとして残す。GitHub にはコメントへ画像を添付する公開 API がないため、
Web UI のアップロード機構をそのまま使う。セッショントークンの抽出・保存は行わない。

## 前提

- Playwright MCP がユーザーのブラウザ (Arc 等) に接続でき、GitHub にログイン済みであること
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
3. **撮影**: Playwright MCP で `http://localhost:<port>/<スライド番号>` を開き、
   `browser_take_screenshot` で `slide-<番号>.png` として撮影する (保存先は cwd 直下になる)。
   撮影後は Read ツールで画像を開き、レイアウト崩れ・はみ出しがないか確認する
   (崩れていたら報告し、貼る前に直すかユーザーに判断を仰ぐ)。
4. **PR ページを新規タブで開く**: `browser_tabs` の `new` で PR の URL を開く。
   **ユーザーが使用中の既存タブを流用しない** (操作が競合する)。
5. **本文の下書き**: コメント欄 textarea (`#new_comment_field`) に `browser_type` で
   仮の見出し (例: `## 変更スライドの表示確認`) を入力する。
6. **画像の添付**: ツールバーの Attach ボタンはバックグラウンドタブだと actionability
   チェック (visible/stable 待ち) で timeout するため、`browser_evaluate` で隠しファイル入力を
   直接クリックしてファイルチューザーを開く:

   ```js
   () => { document.getElementById('fc-new_comment_field').click(); }
   ```

   Modal state が `[File chooser]` になったら `browser_file_upload` で png を
   全部まとめて渡す。
7. **アップロード完了待ち**: 数秒待ってから `browser_evaluate` で
   `document.getElementById('new_comment_field').value` を読み、ファイル数ぶんの
   `<img ... src="https://github.com/user-attachments/assets/...">` が挿入されるまで待つ。
8. **本文の整形**: 得られた `<img>` タグを使って、スライド番号ごとの見出し付き本文を組み立て、
   `browser_type` で textarea に入力し直す (fill なので全置換される)。
9. **送信**: Comment ボタンも actionability で timeout しやすいので `browser_evaluate` で送信する:

   ```js
   () => { document.getElementById('new_comment_field').closest('form')
     .querySelector('button[type="submit"].btn-primary').click(); }
   ```

10. **投稿確認**: `gh pr view <番号> --json comments --jq '.comments[-1].body'` で
    コメント本文が投稿されたことを確認してから完了報告する。
11. **後片付け**: 撮影した png を削除し (リポジトリにはコミットしない)、
    手順 4 で開いたタブを `browser_tabs` の `close` で閉じる。

## 注意

- 画像の実体は `github.com/user-attachments/assets/...` にホストされ、可視性は
  リポジトリに従う (private リポジトリなら画像も private)。
- GitHub のコメント UI の DOM (`new_comment_field` / `fc-new_comment_field`) が
  変わったら snapshot を取り直して要素を特定し直す。
- ユーザーがブラウザを操作中のことがある。タブ一覧が予期せず変わっても慌てず、
  自分が開いたタブだけを操作する。
