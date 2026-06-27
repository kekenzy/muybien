#!/bin/bash
# AWS Lightsail 上で実行するデプロイスクリプト
# 通常は deploy.sh から SSH 経由で呼び出される

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

cd "$PROD_DIR"

echo "🚀 MuyBien 本番デプロイを開始します..."
echo "📂 作業ディレクトリ: $(pwd)"

# .env.prod の存在確認
if [ ! -f ".env.prod" ]; then
    echo "❌ .env.prod が見つかりません。"
    echo "   初回セットアップ: ./scripts/setup_lightsail.sh を実行してください。"
    exit 1
fi

# 自己署名 SSL（IP 直アクセス用）
SSL_DIR="nginx/ssl"
if [ ! -f "${SSL_DIR}/selfsigned.crt" ] || [ ! -f "${SSL_DIR}/selfsigned.key" ]; then
    echo "📜 自己署名 SSL 証明書を生成中..."
    mkdir -p "$SSL_DIR"
    openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
        -keyout "${SSL_DIR}/selfsigned.key" \
        -out "${SSL_DIR}/selfsigned.crt" \
        -subj "/CN=muybien" 2>/dev/null
fi

# フロントビルド成果物の確認
if [ ! -f "myapp-web/app/dist/index.html" ]; then
    echo "❌ myapp-web/app/dist/index.html が見つかりません。"
    echo "   ローカルで npm run build 後、make prod-deploy を実行してください。"
    exit 1
fi

# nginx ドメイン置換（Let's Encrypt 用・将来のドメイン設定時）
NGINX_CONF="nginx/conf.d/production.conf"
if [ -n "$PROD_DOMAIN" ] && grep -q "DOMAIN_PLACEHOLDER" "$NGINX_CONF" 2>/dev/null; then
    echo "⚙️  nginx 設定にドメインを反映: ${PROD_DOMAIN}"
    sed -i "s/DOMAIN_PLACEHOLDER/${PROD_DOMAIN}/g" "$NGINX_CONF"
fi

# Docker / Docker Compose の確認
if ! command -v docker &>/dev/null; then
    echo "❌ Docker がインストールされていません。"
    echo "   ./scripts/setup_lightsail.sh を実行してください。"
    exit 1
fi

# Docker コマンド（グループ未反映時は sudo）
DOCKER="docker"
if ! docker info &>/dev/null 2>&1; then
    DOCKER="sudo docker"
fi

if ! $DOCKER compose version &>/dev/null; then
    echo "❌ Docker Compose v2 が利用できません。"
    exit 1
fi

# コンテナ起動
echo "🐳 Docker コンテナをビルド・起動中..."
$DOCKER compose -f "$COMPOSE_FILE" up --build -d

# 起動待ち
echo "⏳ コンテナの起動を待機中..."
sleep 5

# 状態確認
echo ""
echo "📊 コンテナ状態:"
$DOCKER compose -f "$COMPOSE_FILE" ps

# ヘルスチェック
if $DOCKER compose -f "$COMPOSE_FILE" ps --status running | grep -q muybien-api; then
    echo ""
    echo "✅ API コンテナは起動しています"
else
    echo ""
    echo "⚠️  API コンテナの起動を確認できません。ログを確認してください:"
    echo "   docker compose -f ${COMPOSE_FILE} logs --tail=50 myapp-api"
    exit 1
fi

echo ""
echo "✅ デプロイが完了しました！"
