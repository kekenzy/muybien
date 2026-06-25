#!/bin/bash
# 本番コンテナを停止

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "🛑 本番コンテナを停止中..."
ssh "${SSH_HOST}" "cd ${PROD_DIR} && docker compose -f ${COMPOSE_FILE} down"
echo "✅ 停止完了"
