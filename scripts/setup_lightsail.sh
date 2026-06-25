#!/bin/bash
# AWS Lightsail 初回セットアップスクリプト
# Lightsail インスタンス上で実行する（SSH 接続後）
#
# 使い方:
#   scp -r scripts/ pfweb:/tmp/muybien-scripts
#   ssh pfweb 'bash /tmp/muybien-scripts/setup_lightsail.sh'
#
# または rsync 後:
#   ssh pfweb 'cd /home/ubuntu/muybien && bash scripts/setup_lightsail.sh'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "🚀 AWS Lightsail 初回セットアップを開始します..."

# root 権限が必要な処理
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# システムアップデート
echo "📦 システムをアップデート中..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get upgrade -y -qq

# 必要パッケージ
echo "📦 必要なパッケージをインストール中..."
$SUDO apt-get install -y -qq \
    ca-certificates \
    curl \
    git \
    rsync \
    ufw

# Docker インストール（未インストールの場合）
if ! command -v docker &>/dev/null; then
    echo "🐳 Docker をインストール中..."
    curl -fsSL https://get.docker.com | $SUDO sh
    $SUDO usermod -aG docker "${USER:-ubuntu}" || true
    echo "✅ Docker をインストールしました"
    echo "   ※ docker グループ反映のため、一度ログアウトして再接続してください"
else
    echo "✅ Docker は既にインストール済みです"
fi

# Docker Compose v2 確認
if docker compose version &>/dev/null; then
    echo "✅ Docker Compose v2: $(docker compose version --short)"
else
    echo "❌ Docker Compose v2 が見つかりません。Docker の再インストールを確認してください。"
    exit 1
fi

# プロジェクトディレクトリ作成
echo "📁 プロジェクトディレクトリを作成: ${PROD_DIR}"
$SUDO mkdir -p "$PROD_DIR"
$SUDO chown -R "${USER:-ubuntu}:${USER:-ubuntu}" "$PROD_DIR"

# .env.prod 作成
ENV_FILE="${PROD_DIR}/.env.prod"
if [ ! -f "$ENV_FILE" ]; then
    echo "⚙️  .env.prod を作成中..."
    if [ -f "${PROD_DIR}/env.prod.example" ]; then
        cp "${PROD_DIR}/env.prod.example" "$ENV_FILE"
    elif [ -f "${SCRIPT_DIR}/../env.prod.example" ]; then
        cp "${SCRIPT_DIR}/../env.prod.example" "$ENV_FILE"
    else
        echo "❌ env.prod.example が見つかりません。先に deploy.sh でファイルを転送してください。"
        exit 1
    fi

    # SECRET_KEY / DB パスワードを自動生成
    python3 << PYEOF
import secrets
import re
from pathlib import Path

env_path = Path("${ENV_FILE}")
content = env_path.read_text()
content = content.replace("your-secret-key-here", secrets.token_urlsafe(50))
content = re.sub(r"strong-password-here", secrets.token_urlsafe(18), content)
env_path.write_text(content)
PYEOF

    echo "✅ .env.prod を作成しました"
    echo "⚠️  ${ENV_FILE} を編集して ALLOWED_HOSTS / CORS / メール設定を確認してください"
else
    echo "✅ .env.prod は既に存在します"
fi

# ファイアウォール設定
echo "🔥 ファイアウォールを設定中..."
if command -v ufw &>/dev/null; then
    $SUDO ufw allow OpenSSH
    $SUDO ufw allow 80/tcp
    $SUDO ufw allow 443/tcp
    # docker-compose.prod.yml のポートマッピング（8090/8453）を使う場合
    $SUDO ufw allow 8090/tcp
    $SUDO ufw allow 8453/tcp
    echo "y" | $SUDO ufw enable || true
    echo "✅ ファイアウォールを設定しました"
fi

# Let's Encrypt 用 certbot（オプション）
if ! command -v certbot &>/dev/null; then
    echo "📜 certbot をインストール中（SSL 証明書取得用）..."
    $SUDO apt-get install -y -qq certbot
fi

echo ""
echo "✅ 初回セットアップが完了しました！"
echo ""
echo "次のステップ:"
echo "  1. ${ENV_FILE} を編集（ALLOWED_HOSTS, CORS, SES 等）"
if [ -n "$PROD_DOMAIN" ]; then
    echo "  2. SSL 証明書取得:"
    echo "     sudo certbot certonly --standalone -d ${PROD_DOMAIN}"
    echo "  3. nginx/conf.d/production.conf の DOMAIN_PLACEHOLDER を ${PROD_DOMAIN} に置換"
else
    echo "  2. PROD_DOMAIN を設定して nginx / SSL を構成"
    echo "     例: PROD_DOMAIN=yourdomain.com bash scripts/deploy_lightsail.sh"
fi
echo "  4. ローカルからデプロイ:"
echo "     make prod-deploy"
echo ""
echo "🎉 準備完了！"
