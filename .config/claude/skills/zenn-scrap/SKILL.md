---
name: zenn-scrap
description: >
  zenn.dev のスクラップ (scraps) を Playwright MCP + Arc (CDP) で読み書きする。
  「スクラップに追記して」「スクラップの〇〇スレッドに返信して」「スクラップの本文を直して」
  「zenn に反映して」などのリクエストで使う。スレッド本文と返信の特定、CodeMirror への
  差し替え、::: 記法の注意など zenn 固有の手順を持つ。ブラウザ接続は arc-browser スキルに従う。
allowed-tools: Read, Write, Bash(node -e *), mcp__plugin_playwright_playwright__browser_tabs, mcp__plugin_playwright_playwright__browser_run_code_unsafe
---

# zenn-scrap: zenn スクラップの編集

対象は `https://zenn.dev/<user>/scraps/<id>`。スクラップは「スレッド (先頭の投稿 = 本文)」と
「そのスレッドへの返信」の 2 階層で、どちらも同じ CodeMirror エディタで編集する。
ブラウザは Arc に CDP でアタッチした Playwright MCP を使う (接続・復旧は arc-browser スキル。
凍結タブの復旧で `node -e` を使うため Bash(node -e *) を許可している)。

`browser_run_code_unsafe` はユーザーのログイン済みブラウザで任意 JS を動かす。投稿・編集・削除は
すべて外向きで、編集と削除は復元できない。確認の位置は手順に書いてあるとおりに守る。

## 手順

### 0. 入力を確定する

- **スクラップ URL**: ユーザー指定 > 会話中に出た `zenn.dev/*/scraps/*` > `browser_tabs (list)` で唯一の
  scraps タブ。候補が複数か無しなら URL を尋ねて終了。
- **スレッド名** (返信・編集・削除で必須): 手順 2 の inspect が返す `heading` と完全一致させる。
  ユーザーの言い方が heading と違うときは候補を並べて確認する。
- **本文**: ユーザーの文面をそのまま。zenn markdown への整形 (見出し・折りたたみ) を加えるなら、
  整形後の本文を提示して了承を得る。

### 1. タブを用意する

`browser_tabs (list)` でスクラップのタブを探し、無ければ `browser_tabs (new, url)` で開く。
ユーザーが同じ Arc を操作しているので index はすぐ変わる。**スクリプト実行の直前に list し直す**。
`browser_run_code_unsafe` が `initializeServer: Timeout` で落ちたら arc-browser の「既知の落とし穴」に
従って凍結タブを activate してから再試行する。

### 2. 状態を把握する (inspect)

`scripts/inspect.js` を手順 3 の要領で `.playwright-mcp/zenn-inspect.js` に置いて実行する。戻り値:

```json
{ "ok": true, "hidden": 0, "clean": true,
  "threads": [ { "heading": "Nixのインストール", "replies": 1 }, { "heading": "Macの設定", "replies": 1 } ],
  "editorsOpen": ["スクラップにコメントを追加"] }
```

- `clean: false` (編集/返信フォームが開いたまま) → `scripts/cancel.js` を実行して閉じてから進む。
  開いたままだと別のコメントに投稿・編集してしまう。
- `hidden > 0` で対象スレッドが `threads` に無い → そのスレッドは非表示 (Hidden comment) で編集不能。
  ユーザーに表示へ戻してもらってから再開する。
- 対象スレッドの `heading` を控える (手順 3 の `__THREAD_JSON__` に使う)。

### 3. スクリプトを用意して実行する

操作ごとにテンプレートを選ぶ (`${CLAUDE_SKILL_DIR}/scripts/`)。すべてのプレースホルダは **JSON リテラル**で埋める
(文字列は `"..."`、`__CANDIDATE_JSON__` の dry run は `null`)。バッククォートや `${` のエスケープは不要。

| 操作 | スクリプト | プレースホルダ | 実行前の確認 |
| --- | --- | --- | --- |
| 末尾に新スレッド | `add-thread.js` | `__URL_JSON__`, `__TEXT_JSON__` | 本文を提示して了承 (同じスクラップで了承済みなら省略可) |
| スレッドに返信 | `add-reply.js` | `__URL_JSON__`, `__THREAD_JSON__`, `__TEXT_JSON__` | 同上 |
| 本文/返信を差し替え | `edit-comment.js` | `__URL_JSON__`, `__TARGET_JSON__`, `__THREAD_JSON__`, `__MARKER_JSON__`, `__EXPECT_JSON__`, `__TEXT_JSON__` | **毎回**: 対象 (heading + TARGET + EXPECT) と新本文を提示して了承 |
| 返信を削除 | `delete-reply.js` | `__URL_JSON__`, `__THREAD_JSON__`, `__MARKER_JSON__`, `__CANDIDATE_JSON__` | **毎回**: `null` で dry run → 返った `candidate` を提示して了承 → 転記して本実行 |

- `__MARKER_JSON__`: 対象コメントだけに含まれる一意な文字列。**レンダリング後のテキスト**なので
  markdown 記号 (バッククォート、`#`) は含めない。
- `__EXPECT_JSON__`: 差し替え前の本文の **markdown 原文**の先頭 10〜15 文字 (40 文字以内)。
  heading と違って `##` などの記号を含める。エディタを開いた直後にこれと照合し、違えばキャンセルして
  中断する。本文と返信の取り違え防止の要。
- `__TEXT_JSON__`: 本文は段落から始める (先頭の非見出し行を投稿後の検証 marker に使うため。
  コードフェンスや `:::` から始まると検証が偽陰性になる)。**上限 20,000 文字**。設定ファイルの全文など
  収まらないものは GitHub のリンクにする (スクリプトは超過時に `text too long` で止まる)。

例 (Nix スレッドの返信を差し替える):

```text
inspect → threads: [{ heading: "Nixのインストール", replies: 1 }]
edit-comment: __TARGET_JSON__ "reply", __THREAD_JSON__ "Nixのインストール",
              __MARKER_JSON__ "ここまでで出来るファイルは 2 つ", __EXPECT_JSON__ "##ディレクトリ構成"
```

手順: テンプレートを Read → プレースホルダを置換 → **ワークスペース直下の `.playwright-mcp/zenn-<op>.js`** に
Write → `browser_run_code_unsafe` に `filename: ".playwright-mcp/zenn-<op>.js"` で実行。
`filename` はワークスペースルート相対でしか解決されず、スキルディレクトリや scratchpad は読めない
(`code` 引数でインライン実行もできるが、長い本文は実行前に Read で見直せるファイル方式にする)。

### 4. 戻り値で分岐する

戻り値は `{ ok }` / `{ error, ... }` / `{ dry, candidate }` の 3 形。

| 戻り値 | 対応 |
| --- | --- |
| `ok: true` | 手順 5 へ |
| `ok: false` (error なし) | 投稿・更新は**済んでいる可能性が高い** (反映待ち、または marker がレンダリングに出ない)。再実行せず inspect で確認 |
| `error: "wrong page"` | 現在タブが別ページ。手順 1 からやり直す |
| `error: "editor already open"` | `cancel.js` を実行してから再試行 |
| `error: "thread not found …"` / `"no candidate …"` | inspect で `hidden` と `heading` を再確認。非表示なら中断してユーザーに解除を依頼 |
| `error: "unexpected editor content, cancelled"` | **再実行しない**。`before` をユーザーに見せ、`__TARGET__` / `__EXPECT__` を見直す |
| `error: "candidate changed since dry run"` | DOM が変わった。dry run からやり直す |
| `error: "… head mismatch"` | フォームが開いたまま (edit は自動キャンセル済み)。`cancel.js` → 1 回だけ再試行 |
| `error: "text too long"` | 本文が 20,000 文字超。分割するかリンクにする |
| `ok: false` かつ `editorsOpen` に `内容を編集` が残る | 保存が拒否された (文字数超過など)。画面のエラー文を確認し `cancel.js` で閉じる (confirm ダイアログは自動受諾) |
| `error: "submit button"` | フォームが複数開いている。`cancel.js` で閉じて inspect からやり直す |

### 5. 確認して報告する

inspect を再実行し、`threads[].replies` の増減と `clean: true` を確認する。折りたたみ (`:::details`) の
中身は閉じていると本文検索に出ないので、`summary` 要素のテキストで検証する。

報告に含めるもの: 操作種別 / 対象スレッド heading / スクリプトの戻り値 / inspect の差分 (replies 増減) /
残した `.playwright-mcp/zenn-*.js` のパス (rm は permission deny されることがあるので削除はユーザーに促す)。
`ok: false` で終わった場合は「投稿されたか未確認」と明記する。

## 復帰 (途中で失敗したとき)

1. inspect を実行し `editorsOpen` を見る。
2. `clean: false` なら `cancel.js` で全フォームを閉じる (本文入力済みのフォームが残っていても破棄してよい。
   投稿前なので zenn 側には何も残っていない)。
3. 投稿系 (`add-*`) が `ok: false` だったときは、二重投稿を避けるため inspect の `replies` で反映を確かめてから
   再投稿を判断する。

## 本文の書き方 (zenn markdown)

- 折りたたみ `:::details タイトル` / 注意 `:::message`。**タイトル行にバッククォートを入れない** (記号のまま表示される)。
- コードブロックは `\`\`\`nix:~/path/to/file` でファイル名付き、diff は `\`\`\`diff nix:path`。
- 前方参照を避け、そのコメント単体で読める書き方にする。リンクは `<https://...>`。

## 参考

DOM 構造や過去の事故の詳細は [references/pitfalls.md](references/pitfalls.md)。
スクリプトが `no candidate` / `editor not open` を返す、または DOM を調べ直す必要があるときに読む。
