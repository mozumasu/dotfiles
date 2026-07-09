---
name: arc-browser
description: >
  Playwright MCP を CDP (Chrome DevTools Protocol) 経由で既存の Arc ブラウザに接続し、
  ログイン済みセッションのまま画面操作・スクレイピングを行う。
  claude-in-chrome 拡張が応答しない場合や、Arc で開いている認証済みタブ
  (社内SaaS・管理画面等)をそのまま自動操作したいときに使う。
  「Arcで開いて」「Arcブラウザを操作して」「ログイン済みのタブを使って調べて」
  「利用履歴を取得して」などのリクエストで使用する。
---

# arc-browser: Playwright + CDP で Arc を操作する

Playwright MCP サーバーを、新規に起動した独立ブラウザとしてではなく、
ユーザーが普段使っている **Arc ブラウザに直接アタッチ** して動かす方法。
ログイン済みセッション(Cookie)をそのまま使えるため、Google OAuth 等の
再ログインなしに社内SaaS・管理画面のデータを取得・操作できる。

`claude-in-chrome` 拡張の `tabs_context_mcp` がタイムアウトして応答しない場合の
代替手段としても有効。

## 前提条件

- `playwright` プラグインがインストール済みであること(`/plugin` でインストール、
  未インストールなら `/plugin` → playwright を検索してインストールしてもらう)
- Arc ブラウザ(Chromium ベースで CDP 対応)

## セットアップ手順(初回のみ)

### 1. playwright プラグインの MCP 設定に `--cdp-endpoint` を追加

以下の2ファイルの `args` に `--cdp-endpoint=http://localhost:9222` を追記する
(cache 側とマーケットプレイス clone 側の両方。plugin の再インストール/更新で
上書きされる可能性があるため、都度確認・再適用が必要な場合がある):

```text
~/dotfiles/.config/claude/plugins/marketplaces/claude-plugins-official/external_plugins/playwright/.mcp.json
~/dotfiles/.config/claude/plugins/cache/claude-plugins-official/playwright/<version-hash>/.mcp.json
```

編集後の中身:

```json
{
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest", "--cdp-endpoint=http://localhost:9222"]
  }
}
```

> **注意**: この2ファイルは Nix 管理下ではない(`nix-settings-drift` skill の対象は
> `settings.json` のみ)。plugin marketplace の再クローン等でリセットされる場合は
> 再度この編集が必要。恒常的に使うなら home-manager 側での固定化を検討する。

> **pnpm workspace で作業中の場合**: プロジェクト root の `package.json` に
> `devEngines.packageManager: { name: "pnpm", onFail: "download" }` が入っていると、
> Claude Code は MCP サーバーをそのワークスペース cwd で spawn するため
> `npx @playwright/mcp@latest` が `EBADDEVENGINES` で起動失敗する
> (エラーは silent で、tool が deferred 一覧に出てこないだけ)。
> `.mcp.json` を **`pnpm dlx` に切り替える**と回避できる:
>
> ```json
> {
>   "playwright": {
>     "command": "pnpm",
>     "args": ["dlx", "@playwright/mcp@latest", "--cdp-endpoint=http://localhost:9222"]
>   }
> }
> ```
>
> この症状は Slidev のモノレポ (findy-slidev 等) や Nx workspace で確認済み。
> `mcp__plugin_playwright_playwright__*` が `ToolSearch` で "No matching deferred
> tools found" になったらまずこれを疑う。

### 2. ユーザーに Arc をリモートデバッグ有効で再起動してもらう

Arc が起動中なら **一度完全に終了**してから、以下をユーザー自身に実行してもらう
(`! <command>` プレフィックスでこのセッションから実行依頼できる):

```text
open -a "Arc" --args --remote-debugging-port=9222
```

### 3. 設定を反映

`/reload-plugins` を実行してもらう。以後 `mcp__plugin_playwright_playwright__*`
ツールが CDP 経由で Arc に接続された状態で使えるようになる。

## 使い方

### タブ一覧を確認する

```text
mcp__plugin_playwright_playwright__browser_tabs (action: "list")
```

Arc で現在開いている全タブが一覧表示される。目的のタブ(すでにログイン済み)が
あれば `action: "select", index: N` で切り替える。なければ `browser_navigate` で
新規タブとして開く(既存タブのどれかが `navigate` で上書きされる点に注意 — 必要な
タブは事前に `list` で確認しておく)。

### ページの状態を確認する

- `browser_snapshot`: アクセシビリティツリー(ref付き)を取得。クリック対象の
  要素を特定するのに使う
- `browser_evaluate`: `() => document.body.innerText` 等で軽量にテキスト確認。
  **出力が大きすぎるとトークンオーバーフローするので、巨大なページ
  (診断レポート等)では正規表現で必要な部分だけ抽出する**
  (例: `() => document.body.innerText.match(/診断期間:\s*([^\n]+)/)`)

### クリック操作

`browser_click` の `target` パラメータには `browser_snapshot` で得た `ref` の
値をそのまま渡す(`ref=e548` ではなく `e548` のように `ref=` プレフィックスは
不要)。`element` には人間可読な説明を渡す。

```text
browser_click(element: "利用履歴テーブルの「次へ」ボタン", target: "e548")
```

### ページネーション・繰り返し操作は `browser_run_code_unsafe` でまとめる

1ページごとに `snapshot` → `click` → `snapshot` を繰り返すと往復が多く非効率。
ページネーションを伴うテーブル全件取得のような繰り返し処理は、
`browser_run_code_unsafe` に Playwright の生コードを渡して一括実行するのが速い。

```js
async (page) => {
  const results = [];
  const seen = new Set();
  const getRows = async () => page.evaluate(() => {
    const tables = Array.from(document.querySelectorAll('[role="grid"]'));
    const target = tables.find(t => t.innerText.includes('見出しの一部'));
    if (!target) return null;
    return Array.from(target.querySelectorAll('[role="row"]')).slice(1).map(r =>
      Array.from(r.querySelectorAll('[role="rowheader"], [role="gridcell"]'))
        .map(c => c.innerText.trim())
    );
  });

  for (let i = 0; i < 300; i++) {
    let rows = null;
    for (let attempt = 0; attempt < 6 && !rows; attempt++) {
      rows = await getRows();
      if (!rows) await page.waitForTimeout(1000); // SPAの遅延レンダリング対策
    }
    if (!rows || rows.length === 0) break;
    let newCount = 0;
    for (const r of rows) {
      const key = r.join('|');
      if (!seen.has(key)) { seen.add(key); results.push(r); newCount++; }
    }
    const nextBtn = page.getByRole('button', { name: '次へ' });
    if (await nextBtn.isDisabled().catch(() => true)) break;
    if (newCount === 0 && i > 0) break; // 無限ループ防止
    await nextBtn.click();
    await page.waitForTimeout(900);
  }
  return { count: results.length, results };
}
```

ポイント:

- SPA はページ遷移直後にテーブルが一瞬 DOM から消えることがあるため、
  `getRows` が `null` を返したら数回リトライしてから諦める
- 同一行の重複取得を避けるため `seen` セットでキー管理する
- 「次へ」ボタンが `disabled` になったら終端。無限ループ防止に
  「新規行が0件のまま」も終了条件に入れておく
- ARIA ロールは `role="grid"`(テーブル全体) / `role="row"` / `role="gridcell"`
  であることが多い(`role="table"` ではないので注意。実際のロールは
  `browser_snapshot` の出力で事前に確認する)

## 既知の落とし穴

- **タブが閉じられる/CDP接続が切れる**: `Target page, context or browser has
  been closed` エラーが出たら、`browser_navigate` を再度叩くと再接続される
  ことが多い。`browser_tabs (list)` がタイムアウトする場合も同様
- **ユーザーが同じ Arc ウィンドウを同時に操作している**: タブ一覧が操作の
  合間に変化する(ユーザーが別タブを開く/閉じるなど)。取得中に無関係な
  タブ操作が挟まっても支障はないが、対象タブの index がずれる可能性は
  念頭に置く
- **機密情報の扱い**: 認証済みセッションでアクセスできるページには機微情報
  (脆弱性診断結果、個人情報等)が含まれうる。取得した内容を外部(GitHub Issue
  等)に転記する際は、必要最小限に留め、詳細な脆弱性情報等は記載しない
