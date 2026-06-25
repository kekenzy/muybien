# Let's Encrypt SSL 証明書設定ガイド

本番の HTTPS 関連設定は [PRODUCTION.md](PRODUCTION.md) を参照。ドキュメント全体の索引は [DOCUMENTATION.md](DOCUMENTATION.md) です。

---

## 📋 前提条件

Let's Encrypt で SSL 証明書を取得するには **ドメイン名が必要** です。

- IP アドレスだけでは証明書を発行できない
- DNS の A レコードが Lightsail の静的 IP を向いていること
- ポート 80 が外部から到達可能であること（HTTP-01 チャレンジ用）

MuyBien 本番では Nginx が **Docker コンテナ内** で動作し、証明書は **ホストの `/etc/letsencrypt`** をボリュームマウントして参照します（`docker-compose.prod.yml`）。

---

## 🏗 本番 SSL の仕組み

```
[ブラウザ] ──HTTPS──► [Nginx コンテナ :443]
                          │
                          ├── SSL 証明書: /etc/letsencrypt（ホストマウント）
                          ├── / ──────────► Vue SPA（dist/）
                          └── /v1/api/ ───► Django API（myapp-api:8000）
```

`nginx/conf.d/production.conf` の `DOMAIN_PLACEHOLDER` を実ドメインに置換してから証明書を取得します。

---

## 🔧 設定手順

### 1. ドメインの準備

1. ドメインを取得（例: `muybien.example.com`）
2. DNS で A レコードを Lightsail 静的 IP に設定
3. 反映を待つ（数分〜数時間）

```bash
dig +short yourdomain.com A
# → YOUR_LIGHTSAIL_IP
```

詳細: [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md)

### 2. nginx 設定のドメイン置換

```bash
ssh pfweb
cd /home/ubuntu/muybien
sed -i 's/DOMAIN_PLACEHOLDER/yourdomain.com/g' nginx/conf.d/production.conf
```

またはデプロイ時：

```bash
PROD_DOMAIN=yourdomain.com make prod-deploy
```

### 3. 証明書取得前にコンテナを一時停止

certbot の standalone モードはポート 80 を使用するため、Nginx コンテナを一時停止します。

```bash
ssh pfweb
cd /home/ubuntu/muybien

# Nginx コンテナを停止
docker compose -f docker-compose.prod.yml stop nginx
```

### 4. SSL 証明書の取得

```bash
# certbot が未インストールの場合
sudo apt-get update
sudo apt-get install -y certbot

# 証明書取得（standalone モード）
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive
```

証明書の保存先：

```
/etc/letsencrypt/live/yourdomain.com/fullchain.pem
/etc/letsencrypt/live/yourdomain.com/privkey.pem
```

### 5. コンテナ再起動

```bash
cd /home/ubuntu/muybien
docker compose -f docker-compose.prod.yml up -d
```

`docker-compose.prod.yml` は `/etc/letsencrypt` を Nginx コンテナにマウントしているため、取得済み証明書が自動的に使われます。

### 6. 確認

```bash
# 証明書の確認
sudo certbot certificates

# 自動更新テスト
sudo certbot renew --dry-run

# HTTPS アクセステスト
curl -sI https://yourdomain.com/
```

ブラウザで `https://yourdomain.com` にアクセスし、証明書が有効であることを確認。

---

## 🔄 証明書の自動更新

Let's Encrypt の証明書は 90 日で期限切れになります。Certbot が cron/systemd timer で自動更新します。

更新時は Nginx がポート 80/443 を使っているため、**webroot 方式** または **更新フック** の設定が必要です。

### 更新フックの例

```bash
sudo nano /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

```bash
#!/bin/bash
cd /home/ubuntu/muybien
docker compose -f docker-compose.prod.yml restart nginx
```

```bash
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/restart-nginx.sh
```

---

## ⚠️ 注意事項

1. **ドメイン名が必要**: IP アドレスだけでは証明書を発行できない
2. **DNS 設定**: A レコードが正しく Lightsail IP を向いていること
3. **ポート 80 の開放**: HTTP-01 チャレンジに必要
4. **Cloudflare 利用時**: 証明書取得中は **プロキシをオフ**（灰色の雲）にする
5. **メモリ不足**: 512MB プランでは certbot 実行中に OOM になる場合がある → スワップ追加を検討

### メモリ不足（`Killed`）への対処

```bash
# 2GB スワップ追加
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

---

## 🛠 トラブルシューティング

### 証明書取得に失敗（unauthorized / 404）

Let's Encrypt は `http://yourdomain.com/.well-known/acme-challenge/` にアクセスします。

**確認:**

```bash
dig +short yourdomain.com A @8.8.8.8
# Cloudflare プロキシ OFF 時は Lightsail IP が返ること

sudo tail -50 /var/log/letsencrypt/letsencrypt.log
```

**Cloudflare 利用時**: DNS プロキシをオフにして再実行。

### Nginx 起動失敗（証明書ファイルが見つからない）

```bash
ssh pfweb 'docker logs muybien-nginx --tail=30'
```

- `/etc/letsencrypt/live/yourdomain.com/` が存在するか確認
- `production.conf` の `ssl_certificate` パスがドメインと一致しているか確認
- 証明書取得前に `DOMAIN_PLACEHOLDER` が置換されているか確認

### HTTP → HTTPS リダイレクトループ

`production.conf` の 80 番 server ブロックが HTTPS へ 301 リダイレクトします。  
証明書未取得の状態で 443 が応答できないとループになるため、**先に証明書を取得**してから Nginx を起動してください。

### 証明書を手動更新

```bash
sudo certbot renew
cd /home/ubuntu/muybien && docker compose -f docker-compose.prod.yml restart nginx
```

---

## 📚 参考リンク

- [Let's Encrypt 公式](https://letsencrypt.org/)
- [Certbot 公式](https://certbot.eff.org/)
- [DEPLOYMENT.md](DEPLOYMENT.md) — デプロイ全体の流れ
- [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) — ポート・DNS
