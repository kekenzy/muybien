#!/bin/bash
# AWS EC2 初回セットアップスクリプト（Amazon Linux / Ubuntu 対応）
# EC2 インスタンス上で実行する（SSH 接続後）
#
# 使い方:
#   ssh muy 'cd /home/ec2-user/muybien && bash scripts/setup_lightsail.sh'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "🚀 EC2 初回セットアップを開始します..."

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# OS 判定
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    . /etc/os-release
fi

echo "📦 システムをアップデート中..."
if command -v dnf &>/dev/null; then
    $SUDO dnf update -y -q || echo "⚠️  システムアップデートをスキップしました（パッケージ競合等）"
    $SUDO dnf install -y -q git rsync openssl || $SUDO dnf install -y -q git rsync openssl --allowerasing || true
elif command -v apt-get &>/dev/null; then
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get update -qq
    $SUDO apt-get upgrade -y -qq
    $SUDO apt-get install -y -qq ca-certificates curl git rsync openssl
else
    echo "❌ サポートされていない OS です"
    exit 1
fi

# Docker インストール（Amazon Linux / Ubuntu）
if ! command -v docker &>/dev/null; then
    echo "🐳 Docker をインストール中..."
    if command -v dnf &>/dev/null; then
        $SUDO dnf install -y -q docker
        $SUDO systemctl enable --now docker
        # Compose プラグイン
        $SUDO mkdir -p /usr/local/lib/docker/cli-plugins
        $SUDO curl -fsSL https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64 \
            -o /usr/local/lib/docker/cli-plugins/docker-compose
        $SUDO chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    else
        curl -fsSL https://get.docker.com | $SUDO sh
    fi
    $SUDO usermod -aG docker "${USER:-ec2-user}" || true
    echo "✅ Docker をインストールしました"
    echo "   ※ docker グループ反映のため、一度ログアウトして再接続してください"
else
    echo "✅ Docker は既にインストール済みです"
fi

if ! sudo docker compose version &>/dev/null; then
    echo "❌ Docker Compose v2 が見つかりません"
    exit 1
fi
echo "✅ Docker Compose v2: $(sudo docker compose version --short)"

# プロジェクトディレクトリ
echo "📁 プロジェクトディレクトリ: ${PROD_DIR}"
$SUDO mkdir -p "$PROD_DIR"
$SUDO chown -R "${USER:-ec2-user}:${USER:-ec2-user}" "$PROD_DIR"

# .env.prod 作成
ENV_FILE="${PROD_DIR}/.env.prod"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚙️  .env.prod を作成中..."
    if [ -f "${PROD_DIR}/env.prod.example" ]; then
        cp "${PROD_DIR}/env.prod.example" "$ENV_FILE"
    elif [ -f "${SCRIPT_DIR}/../env.prod.example" ]; then
        cp "${SCRIPT_DIR}/../env.prod.example" "$ENV_FILE"
    else
        echo "❌ env.prod.example が見つかりません"
        exit 1
    fi

    python3 << PYEOF
import secrets
import re
from pathlib import Path

env_path = Path("${ENV_FILE}")
content = env_path.read_text()
content = content.replace("your-secret-key-here", secrets.token_urlsafe(50))
content = re.sub(r"strong-password-here", secrets.token_urlsafe(18), content)
content = content.replace(
    "yourdomain.com,www.yourdomain.com",
    "57.182.190.160,localhost"
)
content = content.replace(
    "https://yourdomain.com,https://www.yourdomain.com",
    "http://57.182.190.160,https://57.182.190.160"
)
content = content.replace(
    "FRONTEND_BASE_URL=https://yourdomain.com",
    "FRONTEND_BASE_URL=https://57.182.190.160"
)
env_path.write_text(content)
PYEOF

    echo "✅ .env.prod を作成しました"
    echo "⚠️  ${ENV_FILE} を編集してメール設定等を確認してください"
else
    echo "✅ .env.prod は既に存在します"
fi

echo ""
echo "✅ 初回セットアップが完了しました！"
echo ""
echo "次のステップ:"
echo "  1. ローカルから: make prod-deploy"
echo "  2. EC2 セキュリティグループで TCP 80 / 443 を開放"
echo ""
