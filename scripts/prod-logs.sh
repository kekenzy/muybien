#!/bin/bash
# 本番ログを表示

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

ssh "${SSH_HOST}" "cd ${PROD_DIR} && docker compose -f ${COMPOSE_FILE} logs -f --tail=100"
