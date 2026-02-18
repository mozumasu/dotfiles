#!/usr/bin/env python3
"""
git push を確実にブロックする PreToolUse hook。
オプションの順番に関わらず、トークン単位で解析する。
クォート内のコンテンツを保護し、ヒアドキュメントの誤検知を防ぐ。
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

# クォート文字列（改行を含む）と演算子を検出するパターン
# グループ1が None → クォート文字列（スキップ）
# グループ1が値あり → 演算子（分割点）
_TOKEN_PAT = re.compile(
    r'"(?:[^"\\]|\\.)*"'        # ダブルクォート文字列
    r"|'(?:[^'\\]|\\.)*'"       # シングルクォート文字列
    r"|(&&|\|\||;|\|(?!\|)|\n)" # 演算子（グループ1のみキャプチャ）
)


def split_commands(s: str) -> list[str]:
    """クォート内を保護しながらシェル演算子でコマンドを分割する"""
    parts = []
    current_start = 0
    for m in _TOKEN_PAT.finditer(s):
        if m.group(1) is None:
            continue  # クォート文字列: 保護してスキップ
        parts.append(s[current_start:m.start()])
        current_start = m.end()
    parts.append(s[current_start:])
    return parts


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


for part in split_commands(cmd):
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
