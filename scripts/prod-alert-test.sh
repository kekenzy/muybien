#!/bin/bash
# 本番からテスト通知を送る（kekenzy@gmail.com 宛て。Django 側 1 通 + サーバー側 1 通）
# 件名: [ALERT][MuyBienBase][error] テスト通知です… / [ALERT][MuyBienBase][intrusion] テスト通知です…

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

echo "📨 Django 側のテスト通知を送信中..."
ssh "${SSH_HOST}" "sudo docker exec muybien-api python manage.py alert test"

echo "📨 サーバー側（fail2ban・死活確認）のテスト通知を送信中..."
ssh "${SSH_HOST}" "sudo python3 ${PROD_DIR}/deploy/alert/muybien_alert.py --env-file ${PROD_DIR}/.env.prod test"
