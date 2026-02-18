#!/usr/bin/env python3
"""
terraform/terragrunt apply を確実にブロックする PreToolUse hook。
&&/||/; で連結されたコマンド列も全トークンを検査する。
"""
import sys
import json
import re
import shlex

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")
if not cmd:
    sys.exit(0)


def is_terraform_apply(tokens: list[str]) -> bool:
    """トークン列が terraform/terragrunt apply コマンドかどうかを判定"""
    if not tokens or tokens[0] not in ("terraform", "terragrunt"):
        return False
    for tok in tokens[1:]:
        if not tok.startswith("-"):
            return tok == "apply"
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
    if is_terraform_apply(tokens):
        print(json.dumps({
            "decision": "block",
            "reason": "terraform/terragrunt applyは自動実行できません。手動で実行してください。",
        }))
        sys.exit(0)

sys.exit(0)
