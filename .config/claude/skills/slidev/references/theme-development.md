# Slidev テーマ・アドオン開発リファレンス

根拠: <https://sli.dev/guide/write-theme> / <https://sli.dev/guide/write-addon> /
<https://sli.dev/guide/write-layout> / <https://sli.dev/custom/directory-structure>

## テーマとアドオンの使い分け

|                        | テーマ                                             | アドオン                                     |
| ---------------------- | -------------------------------------------------- | -------------------------------------------- |
| 1 プロジェクトあたり   | 1 つだけ (`theme:`)                                | 複数可 (`addons:` 配列)                      |
| 適する内容             | グローバルスタイル、デフォルト設定、レイアウト     | コンポーネント、スニペット、コードランナー   |
| 非推奨                 | 独立機能の同梱 (アドオンにすべき)                  | グローバルスタイルや既存レイアウトの上書き   |
| 命名                   | `slidev-theme-*`                                   | `slidev-addon-*`                             |

## ディレクトリ構成 (テーマ・アドオン共通、すべて任意)

```text
slidev-theme-xxx/
├── components/   # カスタムコンポーネント (*.vue, *.ts, *.tsx, *.md)
├── layouts/      # レイアウト用 Vue コンポーネント
├── public/       # 静的アセット
├── setup/        # Shiki, UnoCSS 等のカスタムフック
├── snippets/     # コードスニペット
├── styles/       # グローバルスタイル (index.ts で複数 CSS を import)
├── package.json
└── slides.md     # プレビュー用デモ (theme: ./ を指定)
```

`.vue` / `.ts` はビルドせずソースのまま公開できる。

## package.json

```json
{
  "name": "slidev-theme-xxx",
  "keywords": ["slidev-theme", "slidev"],
  "engines": { "slidev": ">=0.48.0" },
  "slidev": {
    "defaults": {
      "transition": "slide-left",
      "fonts": { "sans": "Noto Sans JP" }
    },
    "colorSchema": "both"
  }
}
```

- `slidev.defaults`: テーマが提供する headmatter のデフォルト値
- `slidev.colorSchema`: `"light"` / `"dark"` / `"both"`

## レイアウトの作り方

`layouts/` に Vue コンポーネントを置き、デフォルトスロットで本文を受ける。

```vue
<!-- layouts/default.vue -->
<template>
  <div class="slidev-layout default">
    <slot />
  </div>
</template>
```

名前付きスロット (スライド側は `::name::` の Slot Sugar 記法):

```vue
<!-- layouts/split.vue -->
<template>
  <div class="slidev-layout split">
    <div class="left"><slot name="left" /></div>
    <div class="right"><slot name="right" /></div>
  </div>
</template>
```

## スタイル

`./style.css` または `./styles/index.{css,js,ts}` がアプリルートに注入される。

```ts
// styles/index.ts
import './base.css'
import './layouts.css'
```

UnoCSS + PostCSS で処理され `--uno:` ディレクティブや `theme()` が使える。
グローバル CSS はプレゼンター UI にも当たるため `.slidev-layout` でスコープすること。

```css
.slidev-layout {
  --uno: px-14 py-10 text-[1.1rem];
  a {
    color: theme('colors.primary');
  }
}
```

## コードブロックのカスタマイズ

`@slidev/client` の `code.css` が `.slidev-code-*` 系クラスと CSS 変数で
フェンスドコードブロックを描画する。テーマ側は基本的に**変数を上書きするだけ**でよい。

DOM 構造 (`CodeBlockWrapper.vue` / `CodeGroup.vue` 実装より):

```text
.slidev-code-wrapper                    ← 外枠。角丸・影はここに付ける
  .slidev-code-block-title (任意)       ← 単体ブロックのファイル名タブ
  .slidev-code-group-tabs (任意)        ← code-group のタブ列 (npm/pnpm 等)
    .slidev-code-tab (複数)
  pre.slidev-code.shiki                 ← 実コード本体
    code
      span.line (行ごと。ハイライト時は .line.highlighted が付く)
  button.slidev-code-copy               ← コピーボタン (configs.codeCopy で有効/無効)
```

主要 CSS 変数 (テーマの `styles/tokens.css` 等で上書きする):

```css
:root {
  --slidev-code-background: #16181d;
  --slidev-code-radius: 10px;
  --slidev-code-padding: 1.1rem;
  --slidev-code-margin: 1rem 0;
  --slidev-code-font-size: 0.82rem;
  --slidev-code-line-height: 1.65;
  --slidev-code-tab-divider: rgba(255, 255, 255, 0.08);
  --slidev-code-tab-text-color: rgba(255, 255, 255, 0.45);
  --slidev-code-tab-active-text-color: #ffffff;
  --slidev-code-line-number: rgba(255, 255, 255, 0.28); /* 既定では未配線。自分で .line::before に当てる必要あり */
}
```

行番号色は変数を定義しただけでは効かない。`code.css` 側の `.line::before` は
UnoCSS ショートハンド (`text-gray-400`) で色を決めているため、テーマ側で明示的に
上書きする:

```css
.slidev-code-line-numbers .slidev-code code .line::before {
  color: var(--slidev-code-line-number) !important;
}
```

行ハイライトは `.line.highlighted` に対してスタイルを当てる:

```css
.slidev-code .line.highlighted {
  display: inline-block;
  width: 100%;
  background: color-mix(in srgb, var(--slidev-theme-primary) 20%, transparent);
  box-shadow: inset 3px 0 0 var(--slidev-theme-primary);
}
```

コードグループのアクティブタブの下線色は `CodeGroup.vue` が
`var(--slidev-theme-primary)` を直接参照しているため、`themeConfig.primary`
(または `--slidev-theme-primary` を直接定義) だけで自動的に揃う。

### Shiki の色を dark/light トグルに依存させない

Shiki は dual theme (`shiki.themes.light`/`dark`) を使うと各 `span` に
`--shiki-light` と `--shiki-dark` の**両方**を inline で埋め込み、
`html.dark` クラスの有無でどちらを使うか `code.css` 側が切り替える。

コードブロックの背景をテーマ側で常にダーク固定にする (Slidev 全体の
light/dark トグルとは独立させる) 場合、この自動切り替えとテキスト色が
噛み合わなくなる (light モードでは暗い文字色が暗い背景に乗って読めなくなる)。
その場合は色の参照先を固定してしまう:

```css
.slidev-code.shiki,
.slidev-code.shiki span {
  color: var(--shiki-dark, inherit) !important;
}
```

## モノレポ管理 (テーマ + アドオンを 1 リポジトリで)

npm の公開単位はパッケージなので、pnpm workspace で複数パッケージを 1 リポジトリ管理できる。
公式の slidevjs/themes も同方式。

```text
my-slidev/
├── pnpm-workspace.yaml   # packages: [packages/*]
├── package.json          # private: true
└── packages/
    ├── slidev-theme-xxx/
    └── slidev-addon-yyy/
```

テーマからアドオンに依存する場合は dependencies に `workspace:*` で参照する
(公開後は npm 解決される)。

## 非公開 (private) での利用

npm 公開は必須ではない。選択肢:

1. **ローカルパス指定** (最も簡単): `theme: ../slidev-theme-xxx`、`addons: [../slidev-addon-yyy]`。
   スライドとテーマを同一 private リポジトリに同居させてもよい
2. **Git 依存**: `"slidev-theme-xxx": "github:user/repo"`。
   モノレポのサブディレクトリ参照は pnpm のみ `github:user/repo#path:packages/xxx` で可能
3. **GitHub Packages**: 自アカウント内 private パッケージは無料。スコープ付き命名になるため
   frontmatter では完全名指定が必要 (`theme: '@scope/slidev-theme-xxx'`)

## 公開する場合

- 命名規約 + keywords を満たして `pnpm publish` (ビルド不要)
- キーワード `slidev-theme` を付けて公開すればテーマギャラリー
  (<https://sli.dev/resources/theme-gallery>) から発見可能になる
