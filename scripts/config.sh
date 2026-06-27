#!/bin/bash
# MuyBien Lightsail デプロイ共通設定
# 環境変数で上書き可能（例: SSH_HOST=muy PROD_DOMAIN=example.com ./scripts/deploy.sh）

# SSH 接続先（~/.ssh/config の Host エイリアス）
SSH_HOST="${SSH_HOST:-muy}"
SSH_USER="${SSH_USER:-ec2-user}"

# サーバー上のプロジェクトディレクトリ
PROD_DIR="${PROD_DIR:-/home/ec2-user/muybien}"

# 本番ドメイン（Let's Encrypt / nginx 設定用。未設定なら手動設定）
PROD_DOMAIN="${PROD_DOMAIN:-}"

# docker-compose ファイル名
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"

# ローカルプロジェクトルート（scripts/ の親ディレクトリ）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# rsync 除外パターン
RSYNC_EXCLUDES=(
  --exclude='.git'
  --exclude='node_modules'
  --exclude='__pycache__'
  --exclude='*.pyc'
  --exclude='.env'
  --exclude='.env.prod'
  --exclude='myapp-api/django/log'
  --exclude='.DS_Store'
)
