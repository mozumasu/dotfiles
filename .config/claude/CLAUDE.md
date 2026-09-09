# AI Coding Rules

- Respond in Japanese.
- 調査・コードリーディング・レビューなどコンテキストを消費する読み取り作業はサブエージェントに委譲する。
  単純な 1 ファイルの編集や既知箇所の修正まで委譲しない。

## Git Commit Message Format

**必須**: コミットメッセージのスタイルは PreToolUse hook が自動検出する。検出されたスタイルに従うこと。

hooks が何も返さない場合のデフォルト:

- Conventional Commits + gitmoji（日本語）
- Format: `<type>: <emoji> <description>`
- Type と Emoji: feat: ✨ / fix: 🐛 / docs: 📝 / style: 💄 / refactor: ♻️ / perf: ⚡️ / test: ✅ / build: 👷 / ci: 🎡 / chore: 🔧

コミット履歴が無い新規リポジトリでは hook が英語・絵文字なしの既定値を返すことがある。
その場合は同じオーナーの既存リポジトリ (`git log` で確認) のスタイルに合わせる。mozumasu/* は日本語 + gitmoji。

## PR 本文

- `gh pr create` / `gh pr edit` の本文は hook (suiko) が日本語の文体を検査し、単調なリズムだとコマンドごと拒否される。
  短い文と長い文を混ぜ、体言止めや一言の文を挟む。
- 本文は heredoc でコマンドに埋め込まず、Write でファイルに書いて `--body-file` で渡す
  (拒否されても git 操作が巻き添えにならない)。

## Text Processing

- **MUST**: Use `perl` instead of `sed` or `awk` for text processing.
  - **Example**:
    - ❌ `sed -i 's/old/new/g' file.txt`
    - ✅ `perl -pi -e 's/old/new/g' file.txt`

- **MUST**: Do not use `cat` to read file. Just use Read tool.
