# AI Coding Rules

- Respond in Japanese.
- Use sub-agents whenever possible.

## Git Commit Message Format

**必須**: Conventional Commits + gitmoji フォーマットを使用

```
<type>: <emoji> <description>

[optional body]
```

**Type と Emoji の対応**:

- feat: ✨ (新機能)
- fix: 🐛 (バグ修正)
- docs: 📝 (ドキュメント)
- style: 💄 (フォーマット、コードスタイル)
- refactor: ♻️ (リファクタリング)
- perf: ⚡️ (パフォーマンス改善)
- test: ✅ (テスト)
- build: 👷 (ビルドシステム)
- ci: 🎡 (CI/CD)
- chore: 🔧 (その他、設定ファイルなど)

**例**:

- `feat: ✨ gitleaksによるシークレットスキャンを追加`
- `fix: 🐛 rumdlの警告を解消`
- `ci: 🎡 actions/checkoutをv6.0.1に更新`

## Text Processing

- **MUST**: Use `perl` instead of `sed` or `awk` for text processing.
  - **Example**:
    - ❌ `sed -i 's/old/new/g' file.txt`
    - ✅ `perl -pi -e 's/old/new/g' file.txt`

- **MUST**: Do not use `cat` to read file. Just use Read tool.
