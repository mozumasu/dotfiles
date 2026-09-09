---
name: headless-render
description: >-
  ローカルの HTML やローカルサーバーの URL をヘッドレス Chrome で PNG にして表示確認する。
  Playwright MCP や claude-in-chrome が使えない (タイムアウトする) ときの代替。
  「スクリーンショットで確認して」「モックを PNG で出して」「スマホ幅で見て」「OGP 画像を作って」
  などのリクエスト、HTML/CSS/WebGL を書いたあとの表示確認で使う。
---

# headless-render: ヘッドレス Chrome で表示確認する

Playwright を使わず、`/Applications/Google Chrome.app` を `--headless=new` で叩いて PNG を得る。
依存のインストールが不要で、Google Fonts も WebGL も動く。

## 基本

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless=new --use-angle=swiftshader --enable-unsafe-swiftshader \
  --hide-scrollbars --no-first-run --ignore-certificate-errors \
  --force-device-scale-factor=2 --window-size=1440,900 --virtual-time-budget=10000 \
  --screenshot=out.png "https://myapp.localhost:1355/?v=$(date +%s)"
```

- `--use-angle=swiftshader --enable-unsafe-swiftshader`: WebGL を有効にする。`--disable-gpu` を付けると WebGL が死ぬ
- `--virtual-time-budget=10000`: フォント読込・アニメーション・fetch を仮想時間で進めてから撮る
- `--ignore-certificate-errors`: portless の `https://*.localhost:1355` (自己署名 CA) 用
- `--force-device-scale-factor=2` で Retina 相当。1 なら軽い
- URL には `?v=$(date +%s)` を付ける。ヘッドレスでもディスクキャッシュが残り、古い HTML を撮ることがある
- `file://` でも撮れるが、絶対パス (`/icon.png`) はルートに解決されて壊れる。ローカルサーバー経由が確実
- Chrome が `/Applications` に無いときは `ls ~/Library/Caches/ms-playwright/` の
  `chromium_headless_shell-*/` (Playwright が落としたもの) を同じフラグで使える。どちらも無ければ
  ユーザーに Chrome のパスを聞く。撮れた PNG は必ず Read で目視してから報告する (真っ黒・真っ白は
  描画前に撮れた合図で、`--virtual-time-budget` を増やすか撮り直す)

## 落とし穴

- **ウィンドウ幅の下限は 500px**。`--window-size=390,844` と指定しても内部は 500px で描かれ、
  レイアウトだけ崩れて見える。スマホ幅は iframe で再現する:

  ```html
  <!-- mobile-frame.html: 600x900 のウィンドウで撮り、左上 390x844 を crop する -->
  <iframe src="https://myapp.localhost:1355/" style="border:0;width:390px;height:844px;display:block"></iframe>
  ```

  `magick shot.png -crop 780x1688+0+0 +repage mobile.png` (scale 2 のとき)
- **スクロール位置は指定できない**。`--screenshot` は常にページ先頭を撮る。JS で `scrollTo` しても反映されない。
  下のほうを撮りたいときは、対象より上を `display:none` にした一時コピー (`_c.html`) を作って撮り、消す
- **WebGL の 1 フレーム描画は rAF の中で**。`requestAnimationFrame` の外で描いた WebGL バッファは
  表示されない。固定フレーム用の `?t=秒` のようなモードでも rAF 経由で 1 回描く
- **アニメーションの止め方**: 撮影したい時刻を URL パラメータで受け、`document.timeline` を進めずに
  固定時刻で描く実装にしておくと、同じ絵が何度でも撮れる
- **画像の読み込み待ちは不確実**。外部画像 (サムネイル等) は virtual-time の中で間に合わないことがある。
  画像が抜けていても、そのレンダリングだけでは「壊れている」と判断しない
- 描画の中身を JS で測りたいときは `--dump-dom` と `document.title` への書き込みを組み合わせる:
  ページ側で `document.title = JSON.stringify({...})` してから
  `--dump-dom URL | grep -o '<title>[^<]*</title>'`
- コンソールエラーは `--enable-logging=stderr --v=0` で stderr に出る (`CONSOLE` で grep)。
  `cv_display_link_mac` の ERROR 行はノイズ

## 動画・GIF にする

固定時刻 `?t=` を 0.1 秒刻みで 36 枚撮り、システムの ffmpeg (Nix の `ffmpeg`) で束ねる。
Playwright 同梱の `~/Library/Caches/ms-playwright/ffmpeg-*/ffmpeg-mac` は PNG 入力を読めない。

```sh
ffmpeg -framerate 10 -i frames/f_%03d.png \
  -vf "fps=10,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=160[p];[s1][p]paletteuse" out.gif
ffmpeg -framerate 10 -i frames/f_%03d.png -c:v libx264 -pix_fmt yuv420p -crf 20 out.mp4
```

## OGP 画像

1200x630 のウィンドウで撮って `magick -resize 1200x630` する。ページ側に `?og=1` のような
ヘッダー/フッターを消すモードを用意しておくと構図を作りやすい。
og:image の URL は差し替えのたびに `?v=2` のようにバージョンを上げる (Slack / X が URL 単位でキャッシュする)。
