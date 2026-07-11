---
name: vue-conventions
description: >
  Vue 3 コンポーネント・composable を書く / レビューするときのコーディング規約。
  *.vue ファイルの作成・編集、「Vueコンポーネントを作って」「composableを書いて」
  「Vueのコードをレビューして」などのリクエストで使用する。
  Slidev テーマのレイアウト実装にも適用する (Slidev 固有 API は slidev スキル参照)。
---

# Vue 3 コーディング規約

Vue 公式スタイルガイド (<https://vuejs.org/style-guide/>) をベースにした個人規約。
API の解説ではなく「こう書く」の列挙。API の詳細は docs-researcher / context7 で最新を引くこと。

## 基本方針

- **Composition API + `<script setup lang="ts">` で統一**。Options API は書かない
- SFC のブロック順は `<script>` → `<template>` → `<style>`
- リアクティブ状態は **`ref()` を第一選択**にする (`reactive()` はプリミティブ不可・
  再代入不可・分割代入で喪失の制限があるため使わない)

## 命名

- コンポーネント名は**複数語の PascalCase** (`TodoItem` ○ / `Todo` ×)。ファイル名も PascalCase
- 汎用 presentational コンポーネントは `Base` プレフィックス (`BaseButton`)
- 親に密結合な子は親名をプレフィックス (`TodoListItem`)
- 名前は「最上位概念 → 修飾語」の順 (`SearchButtonClear` ○ / `ClearSearchButton` ×)。略語禁止
- テンプレート内は PascalCase + 内容がなければ自己終了タグ (`<MyComponent />`)

## props / emits / v-model

- props は type-based 宣言 + **Reactive Props Destructure でデフォルト値** (Vue 3.5+):

  ```ts
  const { msg = 'hello', count } = defineProps<{ msg?: string; count: number }>()
  ```

  `withDefaults` は 3.4 以前のレガシー。runtime 宣言と型宣言の混在は不可
- emits は **named tuple 構文** (3.3+)。call signature 構文は使わない:

  ```ts
  const emit = defineEmits<{ change: [id: number] }>()
  ```

- v-model は **`defineModel()`** (3.4+)。`modelValue` prop + emit の手動実装はしない
- props の直接変更は禁止 (props down, events up)

## script setup

- コンポーネントオプションは `defineOptions()` (別 `<script>` ブロックを作らない)
- 外部公開が必要なものだけ `defineExpose()`
- テンプレート ref は `useTemplateRef()` (3.5+)。`ref(null)` + 同名変数の旧パターンは使わない
- provide/inject は `InjectionKey<T>` で型付けする

## composables

- 命名は `use` + camelCase (`useMouse`)。`composables/` ディレクトリに置く
- 引数は ref / getter / 生値を受けられるようにし `toValue()` で正規化する
- 戻り値は **refs を含むプレーンオブジェクト** (`reactive()` で包まない)
- DOM 副作用は `onMounted()` 内 + `onUnmounted()` で必ずクリーンアップ
- 呼び出しは `<script setup>` / ライフサイクルフック内で同期的に行う

## テンプレート

- `v-for` には必ず一意な `key`
- `v-if` と `v-for` を同一要素に併用しない (computed でフィルタ or `<template>` でラップ)
- 複雑な式は computed へ。複雑な computed は小さく分割
- `v-html` は使わない (XSS)。改行入りテキストの描画は行分割した配列を `v-for` で回す
- ディレクティブは短縮記法 (`:` `@` `#`) で統一。属性値は常にクォート
- 複数属性の要素は 1 属性 1 行

## スタイル

- コンポーネントのスタイルは `scoped` にする (ルートレイアウトは例外)
- `scoped` 内で要素セレクタを使わない (class セレクタを使う)
