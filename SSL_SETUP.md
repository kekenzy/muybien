# Let's Encrypt SSL 証明書設定ガイド

本番の HTTPS 関連設定は [PRODUCTION.md](PRODUCTION.md) を参照。ドキュメント全体の索引は [DOCUMENTATION.md](DOCUMENTATION.md) です。

---

## 📋 前提条件

Let's Encrypt で SSL 証明書を取得するには **ドメイン名が必要** です。

- IP アドレスだけでは証明書を発行できない
- DNS の A レコードが Lightsail の静的 IP を向いていること
- ポート 80 が外部から到達可能であること（HTTP-01 チャレンジ用）

MuyBien 本番では Nginx が **Docker コンテナ内** で動作し、証明書は **ホストの `/etc/letsencrypt`** をボリュームマウントして参照します（`docker-compose.prod.yml`）。

> **OS**: 本番サーバーは **Amazon Linux 2023**（`dnf` 使用）。`apt-get` は使えません。

---

## 🏗 本番 SSL の仕組み

```
[ブラウザ] ──HTTPS──► [Nginx コンテナ :443]
                          │
                          ├── SSL 証明書: /etc/letsencrypt（ホストマウント）
                          ├── / ──────────► Vue SPA（dist/）
                          └── /v1/api/ ───► Django API（myapp-api:8000）
```

`nginx/conf.d/production.conf` は `muybien.jp` / `www.muybien.jp` 向けに設定済みです。証明書取得後、HTTPS ブロックの証明書パスを Let's Encrypt に差し替えます。

---

## 🔧 設定手順

### 1. ドメインの準備

1. ドメイン `muybien.jp` を取得済みであること
2. DNS で A レコードを Lightsail 静的 IP（`57.182.190.160`）に設定
3. 反映を待つ（数分〜数時間）

```bash
dig +short muybien.jp A
# → 57.182.190.160

dig +short www.muybien.jp A
# → 57.182.190.160（または CNAME → muybien.jp）
```

詳細: [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md)

### 2. nginx 設定の確認

`nginx/conf.d/production.conf` は `server_name muybien.jp www.muybien.jp;` に設定済みです。  
変更後は `make prod-deploy` で反映してください。

```bash
make prod-deploy
```

### 3. 証明書取得前にコンテナを一時停止

certbot の standalone モードはポート 80 を使用するため、Nginx コンテナを一時停止します。

```bash
ssh muy
cd /home/ec2-user/muybien

# Nginx コンテナを停止
docker compose -f docker-compose.prod.yml stop nginx
```

### 4. Certbot のインストール（Amazon Linux 2023）

```bash
ssh muy

# Amazon Linux 2023 公式リポジトリからインストール（推奨）
sudo dnf install -y certbot

# 自動更新タイマーを有効化
sudo systemctl enable --now certbot-renew.timer

# 確認
certbot --version
# certbot 2.6.0
```

> Ubuntu / Debian では `apt-get install certbot` ですが、本番サーバー（Amazon Linux 2023）では **`dnf`** を使います。

<details>
<summary>pip で最新版を入れる場合（任意）</summary>

```bash
sudo dnf install -y python3 augeas-libs
sudo python3 -m venv /opt/certbot
sudo /opt/certbot/bin/pip install --upgrade pip
sudo /opt/certbot/bin/pip install certbot
sudo ln -sf /opt/certbot/bin/certbot /usr/bin/certbot
```

</details>

### 5. SSL 証明書の取得

```bash
ssh muy
cd /home/ec2-user/muybien

# 証明書取得（standalone モード — nginx 停止中に実行）
sudo certbot certonly --standalone \
  -d muybien.jp \
  -d www.muybien.jp \
  --email kenji.nagai@globalway.co.jp \
  --agree-tos \
  --non-interactive
```

証明書の保存先：

```
/etc/letsencrypt/live/muybien.jp/fullchain.pem
/etc/letsencrypt/live/muybien.jp/privkey.pem
```

### 6. nginx 設定を Let's Encrypt 証明書に切り替え

`nginx/conf.d/production.conf` の HTTPS ブロックを編集：

```nginx
ssl_certificate /etc/letsencrypt/live/muybien.jp/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/muybien.jp/privkey.pem;
```

ローカルで編集後、`make prod-deploy` で反映します。

### 7. コンテナ再起動

```bash
cd /home/ec2-user/muybien
docker compose -f docker-compose.prod.yml up -d
```

`docker-compose.prod.yml` は `/etc/letsencrypt` を Nginx コンテナにマウントしているため、取得済み証明書が自動的に使われます。

### 8. 確認

```bash
# 証明書の確認
sudo certbot certificates

# 自動更新テスト
sudo certbot renew --dry-run

# HTTPS アクセステスト
curl -sI https://muybien.jp/
```

ブラウザで `https://muybien.jp` にアクセスし、証明書が有効であることを確認。

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
cd /home/ec2-user/muybien
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

Let's Encrypt は `http://muybien.jp/.well-known/acme-challenge/` にアクセスします。

**確認:**

```bash
dig +short muybien.jp A @8.8.8.8
# Cloudflare プロキシ OFF 時は Lightsail IP が返ること

sudo tail -50 /var/log/letsencrypt/letsencrypt.log
```

**Cloudflare 利用時**: DNS プロキシをオフにして再実行。

### Nginx 起動失敗（証明書ファイルが見つからない）

```bash
ssh muy 'docker logs muybien-nginx --tail=30'
```

- `/etc/letsencrypt/live/muybien.jp/` が存在するか確認
- `production.conf` の `ssl_certificate` パスが `muybien.jp` と一致しているか確認

### HTTP → HTTPS リダイレクトループ

`production.conf` の 80 番 server ブロックが HTTPS へ 301 リダイレクトします。  
証明書未取得の状態で 443 が応答できないとループになるため、**先に証明書を取得**してから Nginx を起動してください。

### 証明書を手動更新

```bash
sudo certbot renew
cd /home/ec2-user/muybien && docker compose -f docker-compose.prod.yml restart nginx
```

---

## 📚 参考リンク

- [Let's Encrypt 公式](https://letsencrypt.org/)
- [Certbot 公式](https://certbot.eff.org/)
- [DEPLOYMENT.md](DEPLOYMENT.md) — デプロイ全体の流れ
- [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) — ポート・DNS
