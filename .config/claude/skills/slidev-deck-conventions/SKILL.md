---
name: slidev-deck-conventions
description: >
  Slidev のスライド (デッキ) を追加・執筆・修正するときの品質規律と検証手順。
  「スライドを追加して」「スライドにおこして」「この内容でスライドを書いて」
  「スライドがはみ出してる」「文字を小さくして収めたい」「レイアウト調整して」
  などのリクエスト、または slides.md の作成・編集で使用する。
  執筆時は 1 枚に載せる文量とレイアウト選択の規律を適用し、
  書き終わりと修正時はスクリーンショットで表示確認する。
  Slidev の一般機能・記法は公式の slidev スキルを併用する。
---

# Slidev: デッキ執筆の規律と検証

スライドを**書くとき**から適用する。はみ出してから直すのは二度手間。

## 執筆時の規律

**1 枚に載せる量**

- スライドに残すのは骨子だけ。補足・経緯・注意書きはスピーカーノート
  (`<!-- -->`) へ。読み上げない文はスライドに置かない
- 表のセル・カラム内の文は**折り返さない長さ**に切り詰める。
  折り返しは 1 行を 2〜3 行に化けさせ、あふれの主因になる

**レイアウトの選択**

- 説明 + コード/設定例 → `two-cols` (説明左・コード右、`ratio: 1/1.2`、
  `valign: center`)。縦積みはコードブロックの右が遊びがち
- 一覧・目次的な内容 → 箇条書きよりテーマの専用コンポーネント
  (findy テーマなら FindyAgendaItem 等) が省スペースで見栄えも良い
- 章扉 (section) はタイトル + 短い副題まで。本文を置かない
- 詰め込みが避けられないときだけ frontmatter `zoom: 0.8` で縮小
  (<https://sli.dev/features/zoom-slide>)。全文字が縮む対症療法なので
  最後の手段。PowerPoint の autofit 相当の自動調整は Slidev に存在しない

## 検証: スクリーンショットが一次情報

**Slidev は表示中スライドの前後を DOM に先読み描画する**ため、
`document.querySelector(".slidev-layout")` や h1 の innerText は
表示中とは別のスライドを返すことがある。DOM 計測だけで判断しない。

- スライド番号の特定・はみ出し確認は**スクリーンショット**で行う
- `scrollHeight - clientHeight` が 0 でも footer への食い込みは起きる
  (footer は絶対配置のため)。重なりはスクショで見る
- スライドを書き終えたら該当ページを撮って目視してからコミットする

### ヘッドレス検証スニペット (Arc CDP が使えないときもこれで)

デッキの devDependencies に playwright-chromium が入っている前提:

```sh
cd <デッキのディレクトリ> && node --input-type=module -e '
import { chromium } from "playwright-chromium";
const browser = await chromium.launch();
const page = await browser.newPage({ ignoreHTTPSErrors: true, viewport: { width: 1280, height: 720 } });
await page.goto("https://<portless名>.localhost:1355/<N>", { waitUntil: "networkidle" });
await page.waitForTimeout(1200);
await page.screenshot({ path: "<scratchpad>/slide-N.png" });
await browser.close();'
```

- portless の URL は `portless list` で確認 (`ignoreHTTPSErrors` 必須)
- 撮った画像を Read して目視。番号がずれていたら前後を撮り直す
- 全スライド走査するときも最終判断はスクショ。DOM 計測は候補出しまで

## はみ出しを直すときの優先順位

1. **レイアウトの見直し (根治)** — two-cols 化、コンポーネント化、スライド分割
2. **文言の圧縮** — 骨子化、ノートへの退避、セルの 1 行化
3. **zoom (最後の手段)** — `zoom: 0.8` 等

## トラブルシュート

- HMR が git 操作 (stash / rebase) 後に古い状態を配信することがある。
  ファイルと表示が食い違ったら `touch slides.md`、直らなければ
  dev サーバー再起動 (`ghost stop` → `ghost run -- portless ...`)
