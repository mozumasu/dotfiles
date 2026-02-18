#!/usr/bin/env python3
"""
terraform/terragrunt apply を確実にブロックする PreToolUse hook。
&&/||/; で連結されたコマンド列も全トークンを検査する。
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


def is_terraform_apply(tokens: list[str]) -> bool:
    """トークン列が terraform/terragrunt apply コマンドかどうかを判定"""
    if not tokens or tokens[0] not in ("terraform", "terragrunt"):
        return False
    for tok in tokens[1:]:
        if not tok.startswith("-"):
            return tok == "apply"
    return False


for part in split_commands(cmd):
    part = part.strip()
    if not part:
        continue
    try:
        tokens = shlex.split(part)
    except ValueError:
        tokens = part.split()
    if is_terraform_apply(tokens):
        print(json.dumps({
            "decision": "block",
            "reason": "terraform/terragrunt applyは自動実行できません。手動で実行してください。",
        }))
        sys.exit(0)

sys.exit(0)
