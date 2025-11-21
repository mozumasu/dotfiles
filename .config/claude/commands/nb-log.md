session-exporter Subagentを使用して、このセッション全体のログを~/src/github.com/mozumasu/nbに保存してください。

## 引数の扱い

- **引数あり**: 指定されたノートブックに保存
  - 例: `/nb-log work` → `~/src/github.com/mozumasu/nb/work/YYYYMMDDHHMMSS.md`
- **引数なし**: デフォルトで `log` ノートブックに保存
  - 例: `/nb-log` → `~/src/github.com/mozumasu/nb/log/YYYYMMDDHHMMSS.md`

**有効なノートブック名**: `content`, `home`, `java`, `log`, `work`

## session-exporterの実行内容

session-exporterエージェントが以下を自動的に実行します：

1. **セッション内容の抽出**
   - ユーザープロンプト、ツール呼び出し、実行結果をすべて記録
   - エラーや警告も含めて完全に記録

2. **情報の検証**
   - 公式ドキュメントへの言及を検証（WebFetch/context7使用）
   - リンクの有効性確認
   - 不正確な情報には `[!WARNING]` 注釈を追加

3. **タグの自動生成**
   - セッション内容から適切なハッシュタグを生成
   - nb標準形式: `#tag1 #tag2 #tag3`
   - 技術、テーマ、ドメインに基づいて選定

4. **マークダウンフォーマット**
   - `markdown-session-format` Skillの規約に従って整形
   - タイトル直後にハッシュタグを配置
   - 時系列順に対話履歴を整理

5. **ファイル保存**
   - ファイル名: `YYYYMMDDHHMMSS.md`（実行時刻）
   - 保存先: 指定されたノートブック（デフォルト: `log`）
   - nbは自動コミットされるため、git操作は不要

## 品質基準

- **公式ドキュメント重視**: context7で事実確認
- **事実ベース**: 推論と事実を明確に区別
- **完全性**: すべてのやり取りを漏れなく記録
- **再現性**: 他者が同じ手順を追える形式
- **検索性**: 適切なハッシュタグで分類
- **学習価値**: 成功と失敗の両方を記録
