~/src/github.com/mozumasu/nb/homeにここまでのログをマークダウン形式で追加して
nbは自動コミットされるためコミット不要

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
