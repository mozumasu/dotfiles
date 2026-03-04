`.github/PULL_REQUEST_TEMPLATE.md` に従って PR の下書きを `pr.md` に書いてください。

以下を実施してくださ：
1. テンプレートを読み込む
2. 追加/変更/削除ファイルを整理して箇条書きに
3. 備考に terraform plan 結果や CI 状況を記載
4. `pr.md` に書き出す

## PR 下書きルール

PR 下書きを作成するときは
- `.github/PULL_REQUEST_TEMPLATE.md` がある場合は必ずそれに従う
- `terraform plan` の結果は「Plan: X to add」を明記する
- 根拠リンクは公式ドキュメントを使う (推測で PR を貼らない)
- `pr.md` に出力する
