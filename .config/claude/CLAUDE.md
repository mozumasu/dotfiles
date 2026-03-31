# AI Coding Rules

- Respond in Japanese.
- Use sub-agents whenever possible.

## Git Commit Message Format

**必須**: コミットメッセージのスタイルは PreToolUse hook が自動検出する。検出されたスタイルに従うこと。

hooks が何も返さない場合のデフォルト:

- Conventional Commits + gitmoji（日本語）
- Format: `<type>: <emoji> <description>`
- Type と Emoji: feat: ✨ / fix: 🐛 / docs: 📝 / style: 💄 / refactor: ♻️ / perf: ⚡️ / test: ✅ / build: 👷 / ci: 🎡 / chore: 🔧

## Text Processing

- **MUST**: Use `perl` instead of `sed` or `awk` for text processing.
  - **Example**:
    - ❌ `sed -i 's/old/new/g' file.txt`
    - ✅ `perl -pi -e 's/old/new/g' file.txt`

- **MUST**: Do not use `cat` to read file. Just use Read tool.
