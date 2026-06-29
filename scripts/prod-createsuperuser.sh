#!/bin/bash
# 本番で Django スーパーユーザー作成

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "👤 本番でスーパーユーザーを作成します..."
ssh -t "${SSH_HOST}" "sudo docker exec -it muybien-api python manage.py createsuperuser"
