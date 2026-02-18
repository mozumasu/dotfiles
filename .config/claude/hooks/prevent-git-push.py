#!/usr/bin/env python3
"""
git push を確実にブロックする PreToolUse hook。
オプションの順番に関わらず、トークン単位で解析する。
"""
import sys
import json
import re
import shlex

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")
if not cmd:
    sys.exit(0)

# 引数を別トークンで受け取る git グローバルオプション
OPTS_WITH_ARGS = {
    "-C", "-c",
    "--git-dir", "--work-tree", "--namespace",
    "--exec-path", "--super-prefix", "--config-env",
}


def is_git_push(tokens: list[str]) -> bool:
    """トークン列が git push コマンドかどうかをトークン単位で判定"""
    if not tokens or tokens[0] != "git":
        return False
    i = 1
    while i < len(tokens):
        tok = tokens[i]
        if not tok.startswith("-"):
            # サブコマンドに到達
            return tok == "push"
        if "=" in tok:
            # --key=value 形式はトークン1つで完結
            i += 1
        elif tok in OPTS_WITH_ARGS:
            # -C /path や -c name=val: オプションと引数の2トークンをスキップ
            i += 2
        else:
            i += 1
    return False


# シェル演算子で分割して各コマンドをチェック
# &&, ||, ;, |（単体）, 改行 で分割
parts = re.split(r"\s*(?:&&|\|\||;)\s*|\s*\|(?!\|)\s*|\n", cmd)

for part in parts:
    part = part.strip()
    if not part:
        continue
    try:
        tokens = shlex.split(part)
    except ValueError:
        tokens = part.split()
    if is_git_push(tokens):
        print(json.dumps({
            "decision": "block",
            "reason": "git pushは自動実行できません。手動でpushしてください。",
        }))
        sys.exit(0)

sys.exit(0)
