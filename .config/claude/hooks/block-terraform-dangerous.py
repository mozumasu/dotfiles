#!/usr/bin/env python3
"""
terraform/terragrunt apply / destroy / state push を確実にブロックする PreToolUse hook。
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


def get_block_reason(tokens: list[str]) -> str | None:
    """ブロック対象なら理由文字列を、そうでなければ None を返す"""
    if not tokens or tokens[0] not in ("terraform", "terragrunt"):
        return None

    # グローバルフラグをスキップして最初のサブコマンドを取得
    i = 1
    while i < len(tokens) and tokens[i].startswith("-"):
        i += 1
    if i >= len(tokens):
        return None
    subcmd = tokens[i]

    if subcmd == "apply":
        return "terraform/terragrunt apply は自動実行できません。手動で実行してください。"

    if subcmd == "destroy":
        return "terraform/terragrunt destroy は自動実行できません。手動で実行してください。"

    if subcmd == "state":
        # state サブコマンドのフラグをスキップして次のサブコマンドを確認
        j = i + 1
        while j < len(tokens) and tokens[j].startswith("-"):
            j += 1
        if j < len(tokens) and tokens[j] == "push":
            return "terraform state push は自動実行できません。手動で実行してください。"

    return None


for part in split_commands(cmd):
    part = part.strip()
    if not part:
        continue
    try:
        tokens = shlex.split(part)
    except ValueError:
        tokens = part.split()
    reason = get_block_reason(tokens)
    if reason:
        print(json.dumps({"decision": "block", "reason": reason}))
        sys.exit(0)

sys.exit(0)
