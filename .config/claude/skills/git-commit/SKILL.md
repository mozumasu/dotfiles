---
name: git-commit
description: Stage meaningful diffs and create commits with WHY-focused messages. Use when agent needs to commit code changes.
---

## DISCIPLINE

- pre-commit設定時は検査が通る状態でコミット (バイパス禁止)
- 意味のある最小単位でコミット
    - `git status --short --untracked-files` で確認し **`--untracked-files=no` を使わない**
- メッセージが複数の意味を示す時は分割
- レビュー対応を「レビュー修正」等で1コミットに纏めない。各修正を個別の意味単位でコミットする
- コミットメッセージのprefixはcommitlint.config.cjsファイルが存在するプロジェクトではこのルールに従うこと
- コミットを行う条件：
  1. すべてのテストが通過していること
  2. すべてのコンパイラ/リンタ警告が解決されていること
  3. 変更内容が論理的に一貫した作業単位であること
  4. コミットメッセージに、構造的変更か動作的変更のいずれが含まれているかを明確に記載すること
