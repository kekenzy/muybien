#!/bin/bash
# 本番 DB マイグレーション

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "🗄️  本番マイグレーションを実行中..."
ssh "${SSH_HOST}" "docker exec muybien-api python manage.py migrate --noinput"
echo "✅ マイグレーション完了"
