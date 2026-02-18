# terraform pr draft

- prは必ずdraftで作成してください

## PRに記載する内容

PRテンプレートが `.github/PULL_REQUEST_TEMPLATE` にあればそれに従ってください
以下の内容のみ記載してください

## 変更内容

```text
# 追加したファイル
!`result=$(git diff --name-only --diff-filter=A origin/main...HEAD); [ -n "$result" ] && echo "$result" | tree --fromfile . || echo "なし"`

# 変更したファイル
!`result=$(git diff --name-only --diff-filter=M origin/main...HEAD); [ -n "$result" ] && echo "$result" || echo "なし"`

# 削除したファイル
!`result=$(git diff --name-only --diff-filter=D origin/main...HEAD); [ -n "$result" ] && echo "$result" || echo "なし"`
```

- 以下の情報を元に要約を記載してください
  - 差分を確認してください:
    - `git diff origin/main...HEAD`

  - 以下のコミット履歴から重要な意思決定を抽出してPRに含めてください:
    ```bash
    !`git log origin/main..HEAD --pretty=format:"%h %s%n%b%n"`
    ```
