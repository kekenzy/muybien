#!/bin/bash
# 本番 API コンテナのシェルに接続

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

ssh -t "${SSH_HOST}" "docker exec -it muybien-api bash"
