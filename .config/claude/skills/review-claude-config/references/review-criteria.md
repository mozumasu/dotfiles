# レビュー基準

出典: <https://code.claude.com/docs/en/skills.md>, <https://code.claude.com/docs/en/sub-agents.md>, <https://code.claude.com/docs/en/plugins-reference.md>。
数値・仕様は変わりうるため、疑わしい場合は公式ドキュメントを再確認する。

## 1. 規約準拠

### 共通 (frontmatter)

| 項目 | 重要度 | 基準 |
|---|---|---|
| YAML frontmatter が有効 | HIGH | パース失敗は全フィールドが黙って落ちる |
| `name` がケバブケース | HIGH | 小文字とハイフンのみ |
| `description` が存在する | HIGH | 自動発動・delegation 判定に使われる最重要フィールド |
| description にトリガー条件がある | MEDIUM | 「〜のときに使用する」+ 対象ファイルパターン。key use case を先頭に置く |
| description + when_to_use が 1536 文字以内 | MEDIUM | 超過分は切り詰められる |

### skill 固有

| 項目 | 重要度 | 基準 |
|---|---|---|
| ディレクトリ名 = `name` | HIGH | |
| `SKILL.md` が存在する | HIGH | |
| 本文はロード時のみ読まれる前提で書く | MEDIUM | 常駐させたい 1 行ルールは rules/ へ、発動時知識は skill へ |
| ワークフロー型なら手順セクションがある | HIGH | 知識提供型なら判断基準・例で可 |
| 詳細は references/ に分離 | MEDIUM | SKILL.md が 500 行を超えたら分離を検討 |

### agent 固有

| 項目 | 重要度 | 基準 |
|---|---|---|
| `model` が明示されている | MEDIUM | 省略時は inherit。定型チェックリスト型は sonnet、高精度レビュー・設計判断は上位モデル |
| 1 agent = 1 タスク | HIGH | 汎用 agent は非効率。責務を絞る |
| system prompt が焦点を保っている | MEDIUM | 目安 100〜200 行。500 行超は分割を検討 |
| description に発動例がある | MEDIUM | "use proactively" 等で自動 delegation を促せる |
| Input / Output が定義されている | MEDIUM | 呼び出し元から何を受け取り (対象パス等)、何を返すか |

### command 固有

| 項目 | 重要度 | 基準 |
|---|---|---|
| `commands/` 直下にある | HIGH | サブディレクトリ不可 |
| `argument-hint` がある | LOW | 引数を取る場合 |

## 2. プロンプト品質

| 項目 | 重要度 | 基準 |
|---|---|---|
| 各ステップが具体的 | HIGH | 「適切に処理する」のような曖昧な指示を避ける |
| 入力の解決方法が明確 | HIGH | 引数指定・省略時のデフォルト・0 件時の早期終了 |
| 出力フォーマットが定義されている | HIGH | ワークフロー型のみ。知識提供型は N/A |
| Why が書かれている | MEDIUM | MUST/NEVER の多用より理由の説明。理由があると境界事例で正しく判断できる |
| 例示がある | MEDIUM | ❌/✅ の対比、フォールバック側の例も |
| 失敗時の分岐がある | MEDIUM | ツール未インストール・実行失敗・参照不能時の縮退。lint 系は「指摘による非ゼロ終了」と「実行エラー」を区別 |
| 事実の焼き付けを避ける | MEDIUM | 変わりうる数値・収録内容は公式 URL 参照にする |
| 検証不能な指示がない | LOW | 許可ツールで実行できない指示 (WebFetch なしで「最新情報と照合」等) |

## 3. ツール権限の安全性

| 項目 | 重要度 | 基準 |
|---|---|---|
| 本文で使うツールだけ許可 | HIGH | 本文の手順と宣言を突き合わせて過不足を検出 |
| `Bash(*)` 等の広すぎるパターンがない | HIGH | |
| Bash は前綴りマッチに注意 | MEDIUM | `Bash(foo*)` は `foo-evil` にもマッチ。`Bash(foo)` + `Bash(foo *)` に分ける |
| レビュー・調査用途に Write/Edit がない | MEDIUM | read-only 設計を守る |
| 破壊的コマンドの許可がない | HIGH | rm / git push --force / git reset --hard 等 |
| `cd` 前提の手順に `cd` 許可がない矛盾がない | MEDIUM | ファイルパスを引数で渡す方式に寄せる |
| agent は `tools` と `allowed-tools` を併用しない | MEDIUM | どちらかに統一 |
| 知識提供型 skill は許可なしで可 | — | 特例 |

## 4. 設計

| 項目 | 重要度 | 基準 |
|---|---|---|
| 独立サブタスクの並列化 | HIGH | ワークフロー型のみ。依存のないタスクはサブエージェント並列 + 統合ステップ |
| サブエージェントへの指示が自己完結 | MEDIUM | 対象全文・基準・種別を渡し、外部前提に依存させない |
| ステップの入出力と順序が明確 | HIGH | 前段の出力が後段でどう使われるか |
| 段階的読み込み | MEDIUM | メイン定義はワークフローに集中し、詳細基準は references/ へ |
| ユーザー確認の位置が適切 | MEDIUM | 破壊的操作・修正反映の前に AskUserQuestion。サブエージェント内では対話不可 |
| 0 件・対象なし時の早期終了 | LOW | 空のレポートを生成しない |
