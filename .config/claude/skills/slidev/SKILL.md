---
name: slidev
description: >
  Slidev (sli.dev) でスライドの作成・編集、テーマ・アドオンの自作を行う。
  「スライドを作って」「Slidevで発表資料を作りたい」「LT資料を作って」
  「Slidevのテーマを作って」「レイアウトを追加して」「スライドをエクスポートして」
  などのリクエスト、または slides.md や slidev-theme-* / slidev-addon-* を扱う作業で使用する。
---

# Slidev: スライド作成・テーマ開発

Slidev は Markdown + Vue でスライドを書くプレゼンテーションツール。
このスキルはスライド執筆とテーマ・アドオン開発の両方をカバーする。

## 基本コマンド

```sh
pnpm create slidev              # 新規プロジェクト作成
pnpm slidev slides.md           # 開発サーバー起動 (ライブプレビュー)
pnpm slidev export slides.md    # PDF エクスポート (playwright-chromium が必要)
pnpm slidev build slides.md     # SPA としてビルド
pnpm create slidev-theme        # テーマの雛形生成
```

## スライドの書き方

- スライドは `---` で区切る。各スライド先頭の frontmatter で `layout:` などを指定
- 先頭 frontmatter (headmatter) でデッキ全体の設定: `theme:` `addons:` `fonts:` `transition:` など
- Vue コンポーネントを Markdown 内に直接埋め込める
- 名前付きスロットは Slot Sugar 記法 (`::left::` など) で流し込む

```md
---
theme: seriph
transition: slide-left
---

# タイトル

---
layout: two-cols
---

::left::
左カラム

::right::
右カラム
```

## テーマ・アドオンの指定

- `theme:` は 1 つだけ。`seriph` のような短縮名は `@slidev/theme-seriph` (公式) や
  `slidev-theme-seriph` (コミュニティ) に自動解決される。スコープ付きは完全名が必要
- `addons:` は配列で複数指定可
- **ローカルパスも指定できる**: `theme: ./theme` `addons: [../slidev-addon-foo]`。
  npm 公開不要で private リポジトリ運用が可能
- 未インストールのテーマは起動時に自動インストールを提案してくれる

## テーマ・アドオンを自作するとき

詳細は @references/theme-development.md を参照。
レイアウト・コンポーネントの Vue 実装 ($slidev コンテキスト、frontmatter の props 受け取り、
組み込みコンポーネント、ダークモード、UnoCSS の注意点) は @references/vue-patterns.md を参照。
要点:

- 命名規約: `slidev-theme-*` / `slidev-addon-*`。keywords に `slidev-theme` (または `slidev-addon`) と `slidev` を入れる
- テーマは見た目全般 (スタイル・デフォルト設定・レイアウト)、アドオンは独立機能 (コンポーネント等)。機能のテーマ同梱は公式非推奨
- ビルド不要。`.vue` / `.ts` をソースのまま置けば Slidev 側がコンパイルする
- テーマ開発中のプレビューは、テーマ直下に `slides.md` を作り `theme: ./` を指定して `slidev` を起動
- 複数パッケージは pnpm workspace のモノレポで管理する (公式 slidevjs/themes と同じ方式)
- グローバル CSS はプレゼンター UI にも当たるため `.slidev-layout` でスコープする

## 執筆時の注意

- 日本語スライドの文章は japanese-tech-writing スキルの規範に従う
- フォント指定は headmatter の `fonts:` (デフォルトで Google Fonts から自動取得)。
  日本語なら `sans: Noto Sans JP` などを指定する

## 落とし穴 (実案件で踏んだもの)

- **markdown formatter が frontmatter を破壊する**: この環境の PostToolUse hook (`rumdl fmt`) は
  スライド区切り `---` と frontmatter の間に空行を挿入し、frontmatter 内の裸 URL を
  `<https://...>` に変換して壊す。Slidev 用 .md には最初のスライド本文冒頭に
  `<!-- rumdl-disable -->` を入れ、編集後は `git diff` で `---` 直後の空行を確認する
- **`seoMeta.ogImage: auto` は `slidev build` でも Playwright Chromium を要求する**
  (ビルド後に OGP 画像をレンダリングするため)。CI では
  `pnpm exec playwright install --with-deps chromium` が必要。
  ローカルでは playwright-core のバージョン違いで headless shell の revision が
  合わないことがある → `node node_modules/playwright-chromium/cli.js install chromium`
  のようにデッキが依存するパッケージの CLI でインストールする
- **public/ のアセットを fetch するコードは `import.meta.env.BASE_URL` を前置する**。
  `/comments.json` のようなルート絶対パスは GitHub Pages の base path 配下で 404 になる。
  相対パス `./foo.json` も現在スライドの URL 基準で解決され 2 枚目以降で壊れるので不可
- **pnpm 10+ の build scripts 承認**: `esbuild` や `playwright-chromium` の postinstall が
  ブロックされたら `pnpm-workspace.yaml` の `allowBuilds:` で許可する
  (package.json の `pnpm.onlyBuiltDependencies` は pnpm 11 では読まれない)
