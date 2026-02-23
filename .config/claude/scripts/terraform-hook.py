#!/usr/bin/env python3
"""
terraform/terragrunt コマンドを検査する PreToolUse hook。

処理フロー（各コマンド断片ごと）:
  - terraform/terragrunt がトークン内にない → skip
  - apply / destroy / state push → block（docker compose exec 経由でも常にブロック）
  - docker compose exec 経由 → skip（二重インターセプト防止、ブロック判定後）
  - terraform/terragrunt が先頭でない → skip（ルーティング対象外）
  - plan / validate / fmt → allow（exit 0）
  - その他 → compose.yaml 有無を確認し、コンテナを起動して Docker 内で自動実行
"""

import sys
import json
import re
import shlex
import subprocess
import os
from typing import Optional

input_data = json.load(sys.stdin)
cmd = input_data.get("tool_input", {}).get("command", "")
if not cmd:
    sys.exit(0)

# クォート文字列（改行を含む）と演算子を検出するパターン
# グループ1が None → クォート文字列（スキップ）
# グループ1が値あり → 演算子（分割点）
_TOKEN_PAT = re.compile(
    r'"(?:[^"\\]|\\.)*"'  # ダブルクォート文字列
    r"|'(?:[^'\\]|\\.)*'"  # シングルクォート文字列
    r"|(&&|\|\||;|\|(?!\|)|\n)"  # 演算子（グループ1のみキャプチャ）
)

# docker compose exec 経由コマンドの検出パターン（定数化してループ外でコンパイル）
_DOCKER_COMPOSE_EXEC_RE = re.compile(r"\bdocker\s+compose\b.*\bexec\b")

_DANGEROUS = {
    "apply": "terraform/terragrunt apply は自動実行できません。手動で実行してください。",
    "destroy": "terraform/terragrunt destroy は自動実行できません。手動で実行してください。",
}
_STATE_PUSH_BLOCK_MSG = (
    "terraform state push は自動実行できません。手動で実行してください。"
)
_SAFE_COMMANDS = {"plan", "validate", "fmt"}


def split_commands(s: str) -> list[str]:
    """クォート内を保護しながらシェル演算子でコマンドを分割する"""
    parts = []
    current_start = 0
    for m in _TOKEN_PAT.finditer(s):
        if m.group(1) is None:
            continue  # クォート文字列: 保護してスキップ
        parts.append(s[current_start : m.start()])
        current_start = m.end()
    parts.append(s[current_start:])
    return parts


def find_tf_offset(tokens: list[str]) -> Optional[int]:
    """トークンリスト内の terraform/terragrunt の位置（最初の出現）を返す"""
    for i, tok in enumerate(tokens):
        if tok in ("terraform", "terragrunt"):
            return i
    return None


def get_subcommand_idx(tokens: list[str], offset: int = 0) -> Optional[int]:
    """offset から始めてフラグをスキップし、サブコマンドのインデックスを返す"""
    i = offset + 1
    while i < len(tokens) and tokens[i].startswith("-"):
        i += 1
    return i if i < len(tokens) else None


def is_state_push(tokens: list[str], subcmd_idx: int) -> bool:
    """tokens[subcmd_idx] == "state" のとき、次の引数が "push" かどうかを返す"""
    state_arg_idx = subcmd_idx + 1
    while state_arg_idx < len(tokens) and tokens[state_arg_idx].startswith("-"):
        state_arg_idx += 1
    return state_arg_idx < len(tokens) and tokens[state_arg_idx] == "push"


def block(reason: str) -> None:
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)


def allow_modified(new_cmd: str) -> None:
    """コマンドを差し替えて実行する"""
    print(
        json.dumps({"decision": "allow", "modified_tool_input": {"command": new_cmd}})
    )
    sys.exit(0)


def get_work_dir(part: str) -> str:
    """コマンド内の cd 先ディレクトリを抽出、なければ PWD を使用"""
    m = re.search(r"(?:^|&&)\s*cd\s+(\S+)", part)
    if m:
        return m.group(1)
    return os.environ.get("PWD", os.getcwd())


def get_project_root(work_dir: str) -> Optional[str]:
    """git リポジトリルートを取得"""
    try:
        result = subprocess.run(
            ["git", "-C", work_dir, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except FileNotFoundError:
        pass
    return None


def find_compose_file(project_root: str) -> Optional[str]:
    """compose.yaml / compose.yml を探す"""
    for name in ("compose.yaml", "compose.yml"):
        path = os.path.join(project_root, name)
        if os.path.isfile(path):
            return path
    return None


def find_terraform_service(compose_file: str) -> str:
    """compose ファイルから terraform/terragrunt サービス名を取得"""
    try:
        import yaml  # pyright: ignore[reportMissingModuleSource]

        with open(compose_file) as f:
            compose_config = yaml.safe_load(f)
        services = compose_config.get("services", {})
        for name in services:
            if "terraform" in name or "terragrunt" in name:
                return name
    except Exception:
        # yaml が未インストールの場合も含むため Exception で捕捉
        pass
    return "terraform"


def get_container_base(compose_file: str, project_root: str, service: str) -> str:
    """compose.yaml からコンテナ内マウントパスを取得"""
    try:
        result = subprocess.run(
            ["docker", "compose", "-f", compose_file, "config", "--format", "json"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            docker_config = json.loads(result.stdout)
            volumes = (
                docker_config.get("services", {}).get(service, {}).get("volumes", [])
            )
            for vol in volumes:
                if vol.get("source") == project_root:
                    return vol.get("target", "/workspace")
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    return "/workspace"


def route_to_docker(part: str, tokens: list[str]) -> None:
    """Docker 環境を検出してルーティング。compose ファイルがなければ通過（ローカル実行）"""
    work_dir = get_work_dir(part)
    project_root = get_project_root(work_dir)
    if project_root is None:
        return  # git リポジトリ外 → ローカル実行

    compose_file = find_compose_file(project_root)
    if compose_file is None:
        return  # compose ファイルなし → ローカル実行

    service = find_terraform_service(compose_file)
    container_base = get_container_base(compose_file, project_root, service)

    rel_path = work_dir[len(project_root) :].lstrip("/")
    container_dir = f"{container_base}/{rel_path}" if rel_path else container_base
    tf_command = shlex.join(tokens)

    new_cmd = (
        f"docker compose -f {compose_file} up -d {service} && "
        f"docker compose -f {compose_file} exec {service} sh -c "
        f'"cd {container_dir} && {tf_command}"'
    )
    allow_modified(new_cmd)


def process_command_part(part: str) -> None:
    """コマンドの1断片を検査し、必要に応じてブロックまたはルーティングする"""
    try:
        tokens = shlex.split(part)
    except ValueError:
        tokens = part.split()

    # terraform/terragrunt をトークン内のどこかで検索
    terraform_idx = find_tf_offset(tokens)
    if terraform_idx is None:
        return

    subcommand_idx = get_subcommand_idx(tokens, terraform_idx)
    if subcommand_idx is None:
        return
    subcommand = tokens[subcommand_idx]

    # apply / destroy → 常にブロック（docker compose exec 経由でも）
    if subcommand in _DANGEROUS:
        block(_DANGEROUS[subcommand])

    # state push → ブロック（docker compose exec 経由でも）
    if subcommand == "state" and is_state_push(tokens, subcommand_idx):
        block(_STATE_PUSH_BLOCK_MSG)

    # docker compose exec 経由はスキップ（二重インターセプト防止）
    # ブロック判定より後に実行することで、exec 経由の危険コマンドも確実にブロック
    if _DOCKER_COMPOSE_EXEC_RE.search(part):
        return

    # terraform/terragrunt が先頭でない（例: docker run ... terraform）→ ルーティング対象外
    if terraform_idx != 0:
        return

    # plan / validate / fmt → 通過
    if subcommand in _SAFE_COMMANDS:
        return

    # その他（init / import / output 等）→ Docker 環境を検出してルーティング
    route_to_docker(part, tokens)


for part in split_commands(cmd):
    part = part.strip()
    if not part:
        continue
    process_command_part(part)

sys.exit(0)
