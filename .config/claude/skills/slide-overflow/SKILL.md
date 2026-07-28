---
name: slide-overflow
description: >
  Slidev スライドのはみ出し (コンテンツが footer に食い込む・切れる) の
  検出と修正を行う。「スライドがはみ出してる」「文字を小さくして収めたい」
  「詰め込みすぎのスライドを直して」「レイアウト調整して」などのリクエスト、
  またはスライドのレイアウト検証・修正作業で使用する。
  修正はレイアウト見直し → 文言圧縮 → zoom の優先順位で行う。
---

# Slidev: はみ出しの検出と修正

## 検証の鉄則: スクリーンショットが一次情報

**Slidev は表示中スライドの前後を DOM に先読み描画する**ため、
`document.querySelector(".slidev-layout")` や h1 の innerText は
表示中とは別のスライドを返すことがある。DOM 計測だけで判断しない。

- スライド番号の特定・はみ出し確認は **スクリーンショット**で行う
- `scrollHeight - clientHeight` が 0 でも footer への食い込みは起きる
  (footer は絶対配置のため。重なりはスクショで見るのが確実)

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
- 撮った画像を Read して目視する。番号がずれていたら前後を撮り直す
- 全スライド走査するときも最終判断はスクショ。DOM 計測は候補出しまで

## 修正の優先順位

**1. レイアウトの見直し (根治)**

- 縦積みで溢れ + コードブロックの右が空いている → `two-cols` で
  説明 (左) / コード (右) に分ける。`ratio: 1/1.2` で右を広げられる。
  `valign: center` でコード側を縦センターに
- 列に入れた文は**列幅で折り返さない長さ**に切り詰める。列の折り返しは
  1 行が 2〜3 行に化けて溢れの主因になる
- 一覧系の内容は箇条書きより専用コンポーネント
  (findy テーマなら FindyAgendaItem など) が省スペースなことが多い

**2. 文言の圧縮**

- スライドに残すのは骨子だけ。補足・経緯はスピーカーノート (`<!-- -->`) へ
- 表のセルは 1 行に収まる長さへ。折り返した行が行高を倍にする

**3. zoom (最後の手段)**

- frontmatter に `zoom: 0.8` などでそのスライドだけ縮小
  (<https://sli.dev/features/zoom-slide>)
- 全部の文字が一様に小さくなる対症療法。幅の使い方に原因があるなら
  1. で解決するほうが読みやすさを保てる
- PowerPoint の autofit 相当の「自動」調整は Slidev 本体・公式アドオンに
  存在しない (テキスト 1 ボックス用の AutoFitText のみ)

## 修正後

- 同じ URL を撮り直して収まりを目視確認してからコミットする
- HMR が git 操作 (stash / rebase) 後に古い状態を配信することがある。
  ファイルと表示が食い違ったら `touch slides.md`、直らなければ
  dev サーバー再起動 (`ghost stop` → `ghost run -- portless ...`)
