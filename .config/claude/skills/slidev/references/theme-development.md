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

- 命名規約 + keywords を満たして `npm publish` (ビルド不要)
- キーワード `slidev-theme` を付けて公開すればテーマギャラリー
  (<https://sli.dev/resources/theme-gallery>) から発見可能になる
