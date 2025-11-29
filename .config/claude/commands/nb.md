~/src/github.com/mozumasu/nb/logにYYYYMMDDHHMMSS.md形式でファイルを追加し、この内容の説明を書いて
nbは自動コミットされるためコミット不要

## 基本方針

- 公式ドキュメントを重視すること
- context7 を使って公式ドキュメントを参照し、参照した部分については以下のようにリンクを明示すること
  例:

  ```bash
  # 通常版
  brew install --cask wezterm

  # nightly版
  brew install --cask wezterm@nightly
  ```

  > Homebrew: <https://formulae.brew.sh/cask/wezterm>
  > WezTerm公式: <https://wezfurlong.org/wezterm/installation>

- 事実に基づかない推論は避ける
- 推論の場合は「推論:」と明示する
- 実際に行った検証とその結果を事実に基づいて記載する
  実際のエラー文字を記載する
- どうしてその操作を行ったのか、背景や目的を説明する
- 試してだめだった方法も記録として記載する
- リンクが有効なものかチェックする

## 再現可能な手順の記載

技術検証を記録する際は、ユーザーが再現できる手順を記載する:

1. **コマンドは完全な形式で記載**
   - パスは `...` で省略せず完全なパスを記載
   - 環境変数（`AWS_PROFILE`など）を明記
   - macOS/Linux両方で動くコマンドを推奨

2. **出力例を追加**: 各コマンドの期待される出力を記載

3. **計算式の明記**: 数値を導出した計算式を記載
   - 例: `圧縮率 = 圧縮後サイズ ÷ 元サイズ × 100`

4. **前提条件を明記**: 必要なツール、認証情報、環境設定など

例:

```bash
# 作業ディレクトリを作成
mkdir -p /tmp/gzip_test
cd /tmp/gzip_test

# S3からファイルをダウンロード
AWS_PROFILE=hoge aws s3 cp \
  "s3://bucket-name/path/to/file.json" \
  sample.json

# GZIP圧縮（-k: 元ファイルを保持）
gzip -k sample.json

# ファイルサイズを確認
ls -lh sample.json sample.json.gz
```

出力例:

```text
-rw-r--r--  225K  sample.json
-rw-r--r--  1.7K  sample.json.gz
```
