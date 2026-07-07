# Slidev テーマ開発で使う Vue パターン

根拠: <https://sli.dev/guide/global-context> / <https://sli.dev/guide/component> /
<https://sli.dev/builtin/components> / <https://sli.dev/custom/config-unocss>

## $slidev グローバルコンテキスト

テンプレートに自動注入される。スライド Markdown・コンポーネント・レイアウトで直接使える。

| プロパティ              | 内容                                                                    |
| ----------------------- | ----------------------------------------------------------------------- |
| `$slidev.configs`       | headmatter から解決されたプロジェクト設定 (`title` など)                |
| `$slidev.themeConfigs`  | パース済みテーマ設定 (`themeConfig` の値)                               |
| `$nav`                  | `$nav.next()` / `$nav.nextSlide()` / `$nav.go(n)` / `$nav.currentPage`  |
| `$clicks`               | 現在スライドのクリック数 (段階表示の条件に使う)                         |
| `$page`                 | 1 始まりの現在ページ番号                                                |
| `$frontmatter`          | 現在スライドの frontmatter (スライド外のコンポーネントでは空)           |
| `$renderContext`        | `'slide' \| 'overview' \| 'presenter' \| 'previewNext'`                 |

script setup では composables を使う。**必ず `@slidev/client` から import する**
(内部実装の直接 import は非推奨):

```vue
<script setup>
import { useDarkMode, useIsSlideActive, useNav, useSlideContext } from '@slidev/client'

const { $slidev } = useSlideContext()
const { currentPage, currentLayout } = useNav()
const { isDark } = useDarkMode()
const isActive = useIsSlideActive()
</script>
```

注意: `useSlideContext()` を使うとそのコンポーネントでは `$slidev` の自動注入が
無効化されるため、戻り値から取得する。

## global layers (global-bottom.vue / global-top.vue)

全スライドの下 / 上に常時描画されるレイヤー。背景アニメーションやオーバーレイに使う。

- **Slidev は global layers に props を渡さない**。`defineProps` を書いても常に undefined。
  設定は `configs` (headmatter) や `$slidev.themeConfigs` から取る:

```vue
<script setup lang="ts">
import { configs, useNav } from '@slidev/client'

const { currentPage } = useNav() // URL 正規表現 + ポーリングでの自力追跡は不要
const myConfig = configs.myAddonKey ?? {}
</script>
```

- `window.__slidev__` は非公開の内部プロパティ。バージョンアップで壊れるので使わない
- Vue の `onMounted` は戻り値をクリーンアップとして扱わない (React useEffect と違う)。
  リスナー / タイマーの解除は必ず `onUnmounted` に書く

## キーボードショートカット (setup/shortcuts.ts)

テーマ / アドオンのキーバインドは生の keydown リスナーではなく
`defineShortcutsSetup` で登録する (入力欄フォーカス中の抑制を Slidev 側が処理する)。
global layer 側とは CustomEvent で連携するのが定石:

```ts
// setup/shortcuts.ts
import { defineShortcutsSetup } from '@slidev/types'

export default defineShortcutsSetup((nav, baseShortcuts) => [
  ...baseShortcuts,
  {
    key: 'w',
    fn: () => window.dispatchEvent(new CustomEvent('my-toggle')),
    autoRepeat: false,
  },
])
```

```ts
// global-bottom.vue 側: onMounted で addEventListener('my-toggle', ...)、onUnmounted で解除
```

## レイアウトで frontmatter を受け取る

スライドの frontmatter の値は props としてレイアウトに渡される。
公式レイアウトも `defineProps` で受けている:

```vue
<!-- layouts/image-right.vue 相当 -->
<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  image: { type: String },
  backgroundSize: { type: String, default: 'cover' },
})
</script>

<template>
  <div class="grid grid-cols-2 w-full h-full">
    <div class="slidev-layout default"><slot /></div>
    <div class="w-full h-full" :style="{ backgroundImage: `url(${props.image})` }" />
  </div>
</template>
```

- ユーザー側は `layout: image-right` + `image: /foo.png` と書くだけで props に届く
- props で受けない値は `$frontmatter` からも参照できる
- ルート要素には `slidev-layout` クラスを付ける慣例 (テーマ基本スタイルが当たる)

## コンポーネントの提供

`components/*.{vue,ts,tsx,md}` に置くと import 不要でスライドから `<MyComponent />` と
使える (unplugin-vue-components)。テーマ・アドオンも同じ規約で提供する。

## テーマ開発で再利用しやすい組み込みコンポーネント

| コンポーネント                          | 用途                                                          |
| --------------------------------------- | ------------------------------------------------------------- |
| `<Toc />`                               | 目次。`columns` `maxDepth` `mode`。`hideInToc: true` で除外   |
| `<TitleRenderer :no="n" />`             | 指定スライドのタイトル描画。Toc 系の部品に                    |
| `<SlideCurrentNo />` `<SlidesTotal />`  | ページ番号・総数。フッター部品に最適                          |
| `<LightOrDark>`                         | `#light` / `#dark` スロットで出し分け                         |
| `<Link to="42" />`                      | スライド間リンク                                              |
| `<Transform :scale="0.5">`              | 内容のスケーリング                                            |
| `<AutoFitText :max="100" :min="30" />`  | 文字量に応じた自動フォントサイズ                              |
| `<RenderWhen context="presenter">`      | 描画文脈による条件レンダリング。`#fallback` スロットあり      |

## ダークモード対応 (colorSchema: both)

- UnoCSS の `dark:` variant で書き分ける。テーマ共通色は uno.config.ts の shortcut に:

```ts
export default defineConfig({
  shortcuts: {
    'bg-main': 'bg-white text-[#181818] dark:(bg-[#121212] text-[#ddd])',
  },
})
```

- ロジック分岐は `useDarkMode()` の `isDark`、テンプレートは `<LightOrDark>`
- 素の CSS は `html.dark` 配下に切り替わるので `.dark .my-el { ... }` と書く

## UnoCSS の注意点

- デフォルト有効: preset-wind3 (Tailwind 互換), attributify, icons, web-fonts,
  transformer-directives (`--uno:` / `@apply` が CSS 内で使える)
- uno.config.ts はテーマ / アドオン / ユーザーの設定がマージされる。
  テーマ固有ユーティリティは `shortcuts` で提供するのが定石
- **動的に組み立てたクラス名は生成されない** (静的抽出のため)。
  themeConfig などユーザー入力からクラスを組む場合は `safelist` に列挙する
  (UnoCSS 一般仕様: <https://unocss.dev/guide/extracting>)

## themeConfig をユーザーから受け取る

```yaml
---
theme: my-theme
themeConfig:
  primary: '#5d8392'
---
```

受け取りは 2 経路:

1. **CSS 変数 (自動)**: 各キー `x` が `--slidev-theme-x` として注入される。
   テーマ CSS は `color: var(--slidev-theme-primary)` と参照するだけ
2. **JS / テンプレート**: `$slidev.themeConfigs.primary` または `useSlideContext()` 経由
