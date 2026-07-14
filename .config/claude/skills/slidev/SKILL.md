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
- **ローカルパスも指定できる**が、解決基準が theme と addon で異なる:
  - `theme:` は **entry ファイル基準** (`theme: ./` はデッキと同じディレクトリ)
  - `addons:` は **deck ディレクトリの 1 つ上基準** (`@slidev/cli` の `createResolver` が
    `resolve(dirname(importer), name)` で importer にディレクトリを渡すため)。
    addon パッケージ自身の example.md で `./` と書くと親ディレクトリの package.json を
    探しに行き ENOENT で起動失敗する。正しくは `./slidev-addon-foo` (親から見たパス)
  - npm 公開不要で private リポジトリ運用が可能
- 未インストールのテーマは起動時に自動インストールを提案してくれる

## テーマ・アドオンを自作するとき

詳細は [references/theme-development.md](references/theme-development.md) を参照。
レイアウト・コンポーネントの Vue 実装 ($slidev コンテキスト、frontmatter の props 受け取り、
組み込みコンポーネント、ダークモード、UnoCSS の注意点) は
[references/vue-patterns.md](references/vue-patterns.md) を参照。
テーマ開発固有の落とし穴 (予約 frontmatter フィールド、workspace addon の解決) も
各リファレンス内の該当セクションに記載している。
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
- **スタイリングの置き場所は次の優先順位で決める** (デッキの md に CSS を溜めない):
  1. テーマ/アドオンの既存コンポーネント・レイアウト prop で表現できないか探す
  2. 本当にそのスライド限りの微調整だけ、スライド内 `<style>` を使う
  3. 同じ見た目を 2 箇所目に書きそうになったら、コピペせずテーマ/アドオン側に
     コンポーネントや prop として移管する (テーマリポジトリに issue / PR を出す)。
     デッキ側は移管後にそれを使う形へ書き換える

## 落とし穴 (実案件で踏んだもの)

- **スライド内 `<style>` は Vue scoped としてコンパイルされ、レイアウト内部の要素に
  届かない**: `.two-cols-body` のようなレイアウトコンポーネント内部のクラスは、
  スライドの `<style>` からセレクタの specificity をいくら上げても当たらない
  (スライドのコンテンツはレイアウトの子スロットであり、scoped の data 属性が付かないため)。
  `:global()` でページ限定にして書く:

  ```css
  :global(.slidev-page-7 .two-cols-body) {
    align-items: center;
  }
  ```

  ただし同じ調整を複数スライドでコピペし始めたら、テーマ側に prop を生やす
  (例: two-cols の `valign`) のが正しい置き場所。
- **markdown formatter が frontmatter を破壊する**: この環境の PostToolUse hook (`rumdl fmt`) は
  スライド区切り `---` と frontmatter の間に空行を挿入し、`layout: xxx` を `## layout: xxx` に
  誤変換する。**ファイル先頭に `<!-- rumdl-disable -->` を置いてはいけない** — Slidev の
  headmatter パーサは 1 行目が `---` でないと反応せず、`addons:` `theme:` が全て無視される。
  代わりに**プロジェクトルートに `.rumdl.toml` を置いて Slidev の md を除外**する:

  ```toml
  [global]
  exclude = [
    "packages/*/example.md",
    "packages/*/slides.md",
  ]
  ```

- **headmatter と最初のスライド frontmatter を別ブロックにすると空スライドが混入する**:

  ```md
  ---
  theme: ./
  ---

  ---
  layout: cover
  ---

  # 表紙
  ```

  この構造だと Slidev は「空の 1 枚目 + cover の 2 枚目」と解釈する。**headmatter と最初の
  スライドの frontmatter は同じブロックにマージする**:

  ```md
  ---
  theme: ./
  layout: cover
  ---

  # 表紙
  ```

- **`**bold**` は Vue コンポーネント内のインラインスロットでは markdown 解釈されない**:
  `<FindyKeyValue label="..."> **太字** </FindyKeyValue>` は literal `**太字**` として
  表示される。**HTML の `<strong>` を直接書く**か、スロット内容の前後に空行を入れて
  ブロックとして評価させる。

- **rumdl 除外を作った後は `.rumdl.toml` の場所に注意**: hook は編集対象ファイルから見て
  カレントディレクトリ順に config を探す。モノレポ root に置けば全パッケージに効くが、
  グローバル `~/dotfiles/.rumdl.toml` は上書きされない (上書きされてほしいなら
  プロジェクト側で `[global] exclude = []` を明示的に空にする)。
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
- **コードフェンスの `[タイトル]` と `{行ハイライト}` は順序を間違えると無視される**:
  正しくは `` lang [title] {range} ``。`` lang {range} [title] `` のように逆にすると
  `@slidev/cli` の `RE_BLOCK_INFO` 正規表現がタイトルをキャプチャせず、ファイル名タブが
  描画されない (行ハイライトだけは効くので気付きにくい)。

  ```md
  ```ts [app.ts] {2,3}
  const hello = 'world'
  ```
  ```

- **headmatter に `comark: true` を追加しても `::code-group` がテキストのまま出ることがある**:
  `comark` は markdown-it 拡張の初期化に関わる設定のため、Vite の HMR では反映されない。
  **dev サーバーを再起動する**まで `::code-group` ブロックがタブ UI にならず、
  生のコロン区切りテキストとして表示され続ける (中の code fence 自体は正常に動くので
  一見動いているように見えて紛らわしい)。
