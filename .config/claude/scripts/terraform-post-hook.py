#!/usr/bin/env python3
"""
terraform/terragrunt ファイル編集後に terraform fmt / validate を実行する PostToolUse hook。

処理フロー:
  - .tf / .tfvars / .tfvars.json でない → skip
  - compose.yaml あり、コンテナ起動中 → Docker コンテナ内で fmt / validate
  - compose.yaml なし → ローカルで fmt（常時） / validate（.terraform があるとき）
"""

import sys
import json
import os
import subprocess
from typing import Optional

data = json.load(sys.stdin)
file_path = data.get("tool_input", {}).get("file_path", "")

if not file_path:
    sys.exit(0)

TF_EXTS = (".tf", ".tfvars", ".tfvars.json")
if not any(file_path.endswith(ext) for ext in TF_EXTS):
    sys.exit(0)

work_dir = os.path.dirname(os.path.abspath(file_path))


def get_project_root(work_dir: str) -> Optional[str]:
    try:
        result = subprocess.run(
            ["git", "-C", work_dir, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except FileNotFoundError:
        pass
    return None


def find_compose_file(project_root: str) -> Optional[str]:
    for name in ("compose.yaml", "compose.yml"):
        path = os.path.join(project_root, name)
        if os.path.isfile(path):
            return path
    return None


def find_terraform_service(compose_file: str) -> str:
    try:
        import yaml  # pyright: ignore[reportMissingModuleSource]
        with open(compose_file) as f:
            compose_config = yaml.safe_load(f)
        services = compose_config.get("services", {})
        for name in services:
            if "terraform" in name or "terragrunt" in name:
                return name
    except Exception:
        pass
    return "terraform"


def get_container_dir(compose_file: str, project_root: str, service: str, work_dir: str) -> str:
    container_base = "/workspace"
    try:
        result = subprocess.run(
            ["docker", "compose", "-f", compose_file, "config", "--format", "json"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            docker_config = json.loads(result.stdout)
            volumes = docker_config.get("services", {}).get(service, {}).get("volumes", [])
            for vol in volumes:
                if vol.get("source") == project_root:
                    container_base = vol.get("target", "/workspace")
                    break
    except (FileNotFoundError, json.JSONDecodeError):
        pass
    rel_path = work_dir[len(project_root):].lstrip("/")
    return f"{container_base}/{rel_path}" if rel_path else container_base


def is_container_running(compose_file: str, service: str) -> bool:
    try:
        result = subprocess.run(
            ["docker", "compose", "-f", compose_file, "ps", "--status", "running", "--services"],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return service in result.stdout.strip().split("\n")
    except FileNotFoundError:
        pass
    return False


def run_docker(compose_file: str, service: str, container_dir: str, cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["docker", "compose", "-f", compose_file, "exec", service, "sh", "-c",
         f"cd {container_dir} && {cmd}"],
        capture_output=True, text=True,
    )


def run_local(cmd: list, cwd: str) -> Optional[subprocess.CompletedProcess]:
    try:
        return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    except FileNotFoundError:
        return None  # terraform 未インストール


msgs = []

project_root = get_project_root(work_dir)
compose_file = find_compose_file(project_root) if project_root else None

if compose_file and project_root:
    service = find_terraform_service(compose_file)
    if is_container_running(compose_file, service):
        container_dir = get_container_dir(compose_file, project_root, service, work_dir)

        # fmt
        r = run_docker(compose_file, service, container_dir, "terraform fmt .")
        if r.returncode == 0:
            if r.stdout.strip():
                msgs.append(f"[terraform fmt] {r.stdout.strip()}")
        else:
            msgs.append(f"[terraform fmt] error: {r.stderr.strip()}")

        # validate
        r = run_docker(compose_file, service, container_dir, "terraform validate")
        if r.returncode == 0:
            msgs.append("[terraform validate] ✓ Success")
        else:
            msgs.append(f"[terraform validate] failed:\n{(r.stdout + r.stderr).strip()}")
else:
    # ローカル fmt
    r = run_local(["terraform", "fmt", "."], work_dir)
    if r is not None:
        if r.returncode == 0:
            if r.stdout.strip():
                msgs.append(f"[terraform fmt] {r.stdout.strip()}")
        else:
            msgs.append(f"[terraform fmt] error: {r.stderr.strip()}")

    # ローカル validate（初期化済みの場合のみ）
    if os.path.isdir(os.path.join(work_dir, ".terraform")):
        r = run_local(["terraform", "validate"], work_dir)
        if r is not None:
            if r.returncode == 0:
                msgs.append("[terraform validate] ✓ Success")
            else:
                msgs.append(f"[terraform validate] failed:\n{(r.stdout + r.stderr).strip()}")

if msgs:
    print(json.dumps({"systemMessage": "\n".join(msgs)}))

sys.exit(0)
