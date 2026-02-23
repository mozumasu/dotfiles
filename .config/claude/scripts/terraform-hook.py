#!/usr/bin/env python3
"""
terraform/terragrunt コマンドを検査する PreToolUse hook。

処理フロー（各コマンド断片ごと）:
  - terraform/terragrunt がトークン内にない → skip
  - apply / destroy / state push → block（docker compose exec 経由でも常にブロック）
  - docker compose exec 経由 → skip（二重インターセプト防止、ブロック判定後）
  - terraform/terragrunt が先頭でない → skip（ルーティング対象外）
  - plan / validate / fmt → allow（exit 0）
  - その他 → compose.yaml 有無を確認してルーティング
"""

import sys
import json
import re
import shlex
import subprocess
import os

data = json.load(sys.stdin)
cmd = data.get("tool_input", {}).get("command", "")
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


def find_tf_offset(tokens: list[str]) -> int | None:
    """トークンリスト内の terraform/terragrunt の位置（最初の出現）を返す"""
    for i, tok in enumerate(tokens):
        if tok in ("terraform", "terragrunt"):
            return i
    return None


def get_subcommand_idx(tokens: list[str], offset: int = 0) -> int | None:
    """offset から始めてフラグをスキップし、サブコマンドのインデックスを返す"""
    i = offset + 1
    while i < len(tokens) and tokens[i].startswith("-"):
        i += 1
    return i if i < len(tokens) else None


def block(reason: str) -> None:
    print(json.dumps({"decision": "block", "reason": reason}))
    sys.exit(0)


def get_work_dir(part: str) -> str:
    """コマンド内の cd 先ディレクトリを抽出、なければ PWD を使用"""
    m = re.search(r"(?:^|&&)\s*cd\s+(\S+)", part)
    if m:
        return m.group(1)
    return os.environ.get("PWD", os.getcwd())


def get_project_root(work_dir: str) -> str | None:
    """git リポジトリルートを取得"""
    try:
        result = subprocess.run(
            ["git", "-C", work_dir, "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return None


def find_compose_file(project_root: str) -> str | None:
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
            data = yaml.safe_load(f)
        services = data.get("services", {})
        for name in services:
            if "terraform" in name or "terragrunt" in name:
                return name
    except Exception:
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
            config = json.loads(result.stdout)
            volumes = config.get("services", {}).get(service, {}).get("volumes", [])
            for vol in volumes:
                if vol.get("source") == project_root:
                    return vol.get("target", "/workspace")
    except Exception:
        pass
    return "/workspace"


def is_container_running(compose_file: str, service: str) -> bool:
    """コンテナが起動中かどうか確認"""
    try:
        result = subprocess.run(
            [
                "docker",
                "compose",
                "-f",
                compose_file,
                "ps",
                "--status",
                "running",
                "--services",
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            running_services = result.stdout.strip().split("\n")
            return service in running_services
    except Exception:
        pass
    return False


_DANGEROUS = {
    "apply": "terraform/terragrunt apply は自動実行できません。手動で実行してください。",
    "destroy": "terraform/terragrunt destroy は自動実行できません。手動で実行してください。",
}
_SAFE = {"plan", "validate", "fmt"}


for part in split_commands(cmd):
    part = part.strip()
    if not part:
        continue

    try:
        tokens = shlex.split(part)
    except ValueError:
        tokens = part.split()

    # terraform/terragrunt をトークン内のどこかで検索
    tf_idx = find_tf_offset(tokens)
    if tf_idx is None:
        continue

    subcmd_idx = get_subcommand_idx(tokens, tf_idx)
    if subcmd_idx is None:
        continue
    subcmd = tokens[subcmd_idx]

    # apply / destroy → 常にブロック（docker compose exec 経由でも）
    if subcmd in _DANGEROUS:
        block(_DANGEROUS[subcmd])

    # state push → ブロック（docker compose exec 経由でも）
    if subcmd == "state":
        j = subcmd_idx + 1
        while j < len(tokens) and tokens[j].startswith("-"):
            j += 1
        if j < len(tokens) and tokens[j] == "push":
            block("terraform state push は自動実行できません。手動で実行してください。")

    # docker compose exec 経由はスキップ（二重インターセプト防止）
    if re.search(r"\bdocker\s+compose\b.*\bexec\b", part):
        continue

    # terraform/terragrunt が先頭でない（例: docker run ... terraform）→ ルーティング対象外
    if tf_idx != 0:
        continue

    # plan / validate / fmt → 通過
    if subcmd in _SAFE:
        continue

    # その他（init / import / output 等）→ Docker 環境を検出してルーティング
    work_dir = get_work_dir(part)
    project_root = get_project_root(work_dir)
    if project_root is None:
        continue  # git リポジトリ外 → ローカル実行

    compose_file = find_compose_file(project_root)
    if compose_file is None:
        continue  # compose ファイルなし → ローカル実行

    service = find_terraform_service(compose_file)
    compose_filename = os.path.basename(compose_file)
    container_base = get_container_base(compose_file, project_root, service)

    # ローカルパスからコンテナ内パスを計算
    rel_path = work_dir[len(project_root) :].lstrip("/")
    container_dir = f"{container_base}/{rel_path}" if rel_path else container_base

    tf_command = shlex.join(tokens)

    if not is_container_running(compose_file, service):
        block(
            f'[terraform-hook] Docker service "{service}" is not running. '
            f"Run `docker compose -f {project_root}/{compose_filename} up -d {service}` first, then retry."
        )
    else:
        block(
            f"[terraform-hook] This project runs terraform inside Docker. Run this instead:\n"
            f"docker compose -f {project_root}/{compose_filename} exec {service} sh -c "
            f'"cd {container_dir} && {tf_command}"'
        )

sys.exit(0)
