# AI Coding Rules

- Respond in Japanese.
- Use sub-agents whenever possible.

## Text Processing

- **MUST**: Use `perl` instead of `sed` or `awk` for text processing.
  - **Example**:
    - ❌ `sed -i 's/old/new/g' file.txt`
    - ✅ `perl -pi -e 's/old/new/g' file.txt`

- **MUST**: Do not use `cat` to read file. Just use Read tool.
