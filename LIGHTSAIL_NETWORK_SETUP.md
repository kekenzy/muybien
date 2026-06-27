# AWS Lightsail ネットワーク設定ガイド

> 索引: [DOCUMENTATION.md](DOCUMENTATION.md) ／ デプロイ全体: [DEPLOYMENT.md](DEPLOYMENT.md)

---

## 🔒 開放が必要なポート

MuyBien 本番（Docker Compose）で使用するポートです。

### デフォルト構成（`docker-compose.prod.yml`）

| ポート | プロトコル | 用途 |
|--------|-----------|------|
| 22 | TCP | SSH |
| 8090 | TCP | HTTP（Nginx コンテナ → 80） |
| 8453 | TCP | HTTPS（Nginx コンテナ → 443） |

> 8090/8453 は **muy 等の共有サーバー** で他サービスと 80/443 を分ける場合の設定です。  
> MuyBien 専用インスタンスでは `docker-compose.prod.yml` を **80:80 / 443:443** に変更することを推奨します。

### 標準ポート構成（専用サーバー推奨）

`docker-compose.prod.yml` の nginx セクションを変更：

```yaml
ports:
  - "80:80"
  - "443:443"
```

| ポート | プロトコル | 用途 |
|--------|-----------|------|
| 22 | TCP | SSH |
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |

---

## 📋 Lightsail ファイアウォール設定手順

1. [AWS Lightsail Console](https://lightsail.aws.amazon.com/) にアクセス
2. インスタンスを選択
3. 「ネットワーキング」タブ → 「ファイアウォール」
4. 以下のルールを追加：

| アプリケーション | プロトコル | ポート | ソース |
|----------------|-----------|--------|--------|
| SSH | TCP | 22 | 制限推奨（自分の IP のみ） |
| HTTP | TCP | 80 | 任意の場所 |
| HTTPS | TCP | 443 | 任意の場所 |

8090/8453 を使う場合は、カスタム TCP ルールで追加してください。

`setup_lightsail.sh` は UFW（ホスト OS 側）でも同様のポートを開放します。

---

## 🌐 DNS 設定

### A レコード

DNS プロバイダーで Lightsail の **静的 IP** を向ける：

```
Type: A
Name: @
Value: YOUR_LIGHTSAIL_IP

Type: A
Name: www
Value: YOUR_LIGHTSAIL_IP
```

### 反映確認

```bash
dig +short yourdomain.com A
dig +short www.yourdomain.com A
```

**Lightsail の静的 IP と同じ IP** が返ることを確認してください。

---

## 🔍 トラブルシュート: 静的 IP では開くがドメインでは開かない

**原因の多くは DNS が Lightsail の静的 IP を向いていないことです。**

```bash
dig +short yourdomain.com A
# → YOUR_LIGHTSAIL_IP と一致するか確認
```

### Cloudflare を使う場合

- DNS の **A レコード**を Lightsail の静的 IP に設定
- SSL/TLS モードが「フル」または「フル（厳密）」の場合、オリイン側（Nginx コンテナ）の証明書設定と整合させる
- 証明書取得時は **プロキシをオフ**（灰色の雲）にしてから certbot を実行 → [SSL_SETUP.md](SSL_SETUP.md)

### サーバ側が正常かの切り分け

```bash
# IP 直打ち（ポートは構成に合わせる）
curl -sI http://YOUR_LIGHTSAIL_IP:8090/
curl -skI https://YOUR_LIGHTSAIL_IP:8453/

# 標準ポート構成の場合
curl -sI http://YOUR_LIGHTSAIL_IP/
```

200 または 301/302 が返れば Nginx は動作しています。

---

## 🐳 Docker ネットワーク

本番では `muybien-network`（bridge）上で 3 コンテナが通信します：

```
muybien-nginx ──► myapp-api:8000
myapp-api     ──► myapp-db:5432
```

- DB ポートは **ホストに公開しない**（`expose` のみ）
- API ポートも **ホストに公開しない**（Nginx 経由のみ）

---

## 📊 現在の設定確認コマンド

```bash
ssh muy 'cd /home/ec2-user/muybien && docker compose -f docker-compose.prod.yml ps'
ssh muy 'sudo ufw status'
ssh muy 'docker port muybien-nginx'
```

---

## 関連ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [DEPLOYMENT.md](DEPLOYMENT.md) | デプロイ手順 |
| [SSL_SETUP.md](SSL_SETUP.md) | HTTPS 設定 |
| [PRODUCTION.md](PRODUCTION.md) | 環境変数 |
