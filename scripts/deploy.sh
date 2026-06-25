#!/bin/bash
# ローカルから AWS Lightsail へデプロイするスクリプト
# 使い方: ./scripts/deploy.sh  または  make prod-deploy

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "🚀 Lightsail へのデプロイを開始します..."
echo "📍 ターゲット: ${SSH_USER}@${SSH_HOST}:${PROD_DIR}"

# SSH 接続テスト
echo "🔌 SSH 接続をテスト中..."
if ! ssh -o ConnectTimeout=10 "${SSH_HOST}" "echo 'SSH接続成功'" 2>/dev/null; then
    echo "❌ SSH 接続に失敗しました。~/.ssh/config を確認してください。"
    echo ""
    echo "   例:"
    echo "   Host pfweb"
    echo "     HostName YOUR_LIGHTSAIL_IP"
    echo "     User ubuntu"
    echo "     IdentityFile ~/.ssh/your-key.pem"
    exit 1
fi
echo "✅ SSH 接続成功"

# フロントエンドビルド
echo "📦 フロントエンドをビルド中..."
cd "$PROJECT_ROOT/myapp-web/app"
if [ ! -d node_modules ]; then
    npm install
fi
npm run build
cd "$PROJECT_ROOT"

# サーバーにディレクトリ作成
echo "📁 デプロイ先ディレクトリを確認中..."
ssh "${SSH_HOST}" "mkdir -p ${PROD_DIR}"

# ファイル転送
echo "📤 ファイルを転送中..."
rsync -avz --delete \
    "${RSYNC_EXCLUDES[@]}" \
    "$PROJECT_ROOT/" "${SSH_HOST}:${PROD_DIR}/"

# リモートでデプロイスクリプト実行
echo "🔄 本番コンテナを起動中..."
ssh "${SSH_HOST}" "PROD_DIR=${PROD_DIR} PROD_DOMAIN=${PROD_DOMAIN} COMPOSE_FILE=${COMPOSE_FILE} bash ${PROD_DIR}/scripts/deploy_lightsail.sh"

echo ""
echo "✅ デプロイが正常に完了しました！"
echo "🌐 本番確認: ssh ${SSH_HOST} 'cd ${PROD_DIR} && docker compose -f ${COMPOSE_FILE} ps'"
