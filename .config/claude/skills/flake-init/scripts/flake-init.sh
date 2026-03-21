#!/usr/bin/env bash
set -euo pipefail

# Nix flake 環境セットアップスクリプト
# プロジェクトタイプを自動検出し、適切な flake.nix を生成する
#
# Usage: flake-init.sh [project_dir]
#
# 対応プロジェクト:
#   - Terraform (.tf / .terraform-version)
#   - Go (go.mod)
#   - Node.js (package.json)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$SKILL_DIR/templates"
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

cd "$PROJECT_DIR"

# ── Gitリポジトリチェック ──────────────────────────────────
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "❌ エラー: Gitリポジトリではありません: $PROJECT_DIR"
  exit 1
fi

echo "📁 プロジェクトディレクトリ: $PROJECT_DIR"

# ── プロジェクトタイプ検出 ─────────────────────────────────
detect_project_type() {
  if compgen -G "*.tf" >/dev/null 2>&1 || [ -f .terraform-version ]; then
    if [ -f .terraform-version ]; then
      echo "terraform-version-pinned"
    else
      echo "terraform"
    fi
  elif [ -f go.mod ]; then
    echo "go"
  elif [ -f package.json ]; then
    echo "nodejs"
  else
    echo "unknown"
  fi
}

PROJECT_TYPE="$(detect_project_type)"

case "$PROJECT_TYPE" in
  terraform)
    echo "🔍 プロジェクトタイプ: Terraform"
    TEMPLATE_FILE="$TEMPLATE_DIR/terraform.nix"
    ;;
  terraform-version-pinned)
    TF_VERSION=$(tr -d '\n' < .terraform-version)
    echo "🔍 プロジェクトタイプ: Terraform (v${TF_VERSION} 固定)"
    TEMPLATE_FILE="$TEMPLATE_DIR/terraform-version-pinned.nix"
    ;;
  go)
    echo "🔍 プロジェクトタイプ: Go"
    TEMPLATE_FILE="$TEMPLATE_DIR/go.nix"
    ;;
  nodejs)
    echo "🔍 プロジェクトタイプ: Node.js"
    TEMPLATE_FILE="$TEMPLATE_DIR/nodejs.nix"
    ;;
  unknown)
    echo "❌ エラー: プロジェクトタイプを検出できませんでした"
    echo "   対応: *.tf, .terraform-version, go.mod, package.json"
    exit 1
    ;;
esac

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "❌ エラー: テンプレートが見つかりません: $TEMPLATE_FILE"
  exit 1
fi

# ── 1. .envrc の作成・更新 ────────────────────────────────
if [ -f .envrc ]; then
  if grep -q 'use flake' .envrc; then
    echo "✅ .envrc に 'use flake' は既に存在します"
  else
    echo 'use flake' >> .envrc
    echo "✅ .envrc に 'use flake' を追記しました"
  fi
else
  echo 'use flake' > .envrc
  echo "✅ .envrc を作成しました"
fi

# ── 2. flake.nix の作成 ──────────────────────────────────
if [ -f flake.nix ]; then
  echo "⚠️  flake.nix は既に存在します。上書きしますか? [y/N]"
  read -r answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "スキップしました"
    exit 0
  fi
fi

cp "$TEMPLATE_FILE" flake.nix
echo "✅ flake.nix を作成しました（テンプレート: $PROJECT_TYPE）"

# ── 3. git add ───────────────────────────────────────────
git add flake.nix .envrc
echo "✅ git add flake.nix .envrc"

# ── 4. direnv allow ──────────────────────────────────────
if command -v direnv &>/dev/null; then
  direnv allow
  echo "✅ direnv allow を実行しました"
else
  echo "⚠️  direnv が見つかりません。手動で 'direnv allow' を実行してください"
fi

# ── 5. .git/info/exclude の設定 ──────────────────────────
GIT_DIR="$(git rev-parse --git-dir)"
EXCLUDE_FILE="$GIT_DIR/info/exclude"

echo ""
echo ".git/info/exclude に flake.nix, flake.lock, .envrc を追加しますか?"
echo "（リポジトリの .gitignore を変更せずに、自分のローカル環境でのみ無視できます）"
echo -n "[y/N]: "
read -r answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
  mkdir -p "$GIT_DIR/info"

  ENTRIES=(
    "flake.nix"
    "flake.lock"
    ".envrc"
    "# Nix build outputs"
    "result"
    "result-*"
    "# direnv"
    ".direnv"
  )

  for entry in "${ENTRIES[@]}"; do
    if ! grep -qxF "$entry" "$EXCLUDE_FILE" 2>/dev/null; then
      echo "$entry" >> "$EXCLUDE_FILE"
    fi
  done

  echo "✅ .git/info/exclude を設定しました"
else
  echo "スキップしました"
fi

# ── 完了 ─────────────────────────────────────────────────
echo ""
echo "🎉 セットアップ完了！"
echo ""
echo "動作確認:"
echo "  cd && cd -"
echo "  # プロジェクトに戻ると自動で devShell が起動します"
