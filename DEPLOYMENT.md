# AWS Lightsail デプロイ手順書

このドキュメントでは、MuyBien を AWS Lightsail にデプロイする手順を説明します。

> **本番の環境変数・SES・migrate の一覧** は [PRODUCTION.md](PRODUCTION.md) を参照。  
> **リポジトリ内の全 Markdown の索引** は [DOCUMENTATION.md](DOCUMENTATION.md) を参照。

---

## 📋 前提条件

- AWS アカウント
- ローカルに Docker / Node.js 20+ がインストール済み
- SSH 鍵（Lightsail デフォルトキーまたは独自キー）
- ドメイン（SSL 利用時に推奨）

---

## 🏗 デプロイの流れ

```
[ローカル PC]
  npm run build（Vue SPA）
  rsync → Lightsail
       │
       ▼
[EC2 インスタンス /home/ec2-user/muybien]
  docker compose -f docker-compose.prod.yml up --build -d
       │
       ├── nginx    … SPA 配信 + API プロキシ + SSL
       ├── myapp-api … Django + Gunicorn
       └── myapp-db  … PostgreSQL
```

yomohiro_web が **git pull + venv + systemd（Gunicorn/Nginx）** 構成であるのに対し、MuyBien は **Docker Compose オールインワン** 構成です。

---

## 📦 1. AWS Lightsail インスタンスの作成

### 1.1 インスタンスの作成

1. [AWS Lightsail Console](https://lightsail.aws.amazon.com/) にアクセス
2. 「インスタンスの作成」をクリック
3. 以下の設定を選択：
   - **リージョン**: Tokyo (ap-northeast-1)
   - **プラットフォーム**: Linux/Unix
   - **設計図**: OS のみ → Ubuntu 22.04 LTS
   - **インスタンスプラン**: $5/月 (1GB RAM) 以上を推奨（Docker 利用のため）
   - **インスタンス名**: muybien-web（任意）

### 1.2 静的 IP アドレスの割り当て

1. 作成したインスタンスの詳細ページを開く
2. 「ネットワーキング」タブ → 「静的 IP アドレスの作成」
3. 作成した静的 IP をメモ（例: `54.x.x.x`）

詳細は [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) を参照。

### 1.3 SSH キーペアのダウンロード

1. インスタンスの詳細ページで「アカウントページ」タブ
2. 「デフォルトのキー」をダウンロード
3. キーファイルを安全な場所に保存

```bash
chmod 400 LightsailDefaultKey-ap-northeast-1.pem
```

---

## 🔧 2. ローカル SSH 設定

`~/.ssh/config` にエイリアスを追加します（yomohiro_web の `Host yomohiro` と同様）。

```
Host muy
  HostName YOUR_SERVER_IP
  User ec2-user
  IdentityFile ~/.ssh/muybien.pem
```

接続テスト：

```bash
ssh muy "echo OK"
```

---

## 🚀 3. Lightsail 初回セットアップ

### 3.1 ファイル転送（初回）

ローカルでプロジェクトディレクトリから実行：

```bash
# SSH 接続確認のみ（ビルド・転送はまだしない場合）
ssh muy "mkdir -p /home/ec2-user/muybien"

# 初回は deploy.sh がフロントビルドも行うので、先に setup だけしたい場合:
rsync -avz --exclude='node_modules' --exclude='.git' --exclude='__pycache__' \
  ./ muy:/home/ec2-user/muybien/
```

### 3.2 サーバー上で初期セットアップ

```bash
ssh muy
cd /home/ec2-user/muybien
bash scripts/setup_lightsail.sh
```

スクリプトが自動で以下を実行します：

- システムのアップデート
- Docker / Docker Compose v2 のインストール
- プロジェクトディレクトリの作成
- `.env.prod` の生成（`env.prod.example` ベース + SECRET_KEY 自動生成）
- UFW ファイアウォール設定（22, 80, 443, 8090, 8453）

> Docker グループ反映のため、**一度ログアウトして SSH 再接続**してください。

### 3.3 環境変数の設定

```bash
ssh muy
nano /home/ec2-user/muybien/.env.prod
```

最低限、以下を実際の値に変更：

```env
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
EMAIL_HOST_USER=（SES SMTP ユーザー名）
EMAIL_HOST_PASSWORD=（SES SMTP パスワード）
CONTACT_NOTIFY_EMAIL=kenji.nagai@globalway.co.jp
```

詳細は [PRODUCTION.md](PRODUCTION.md) を参照。

### 3.4 nginx ドメイン設定

`nginx/conf.d/production.conf` の `DOMAIN_PLACEHOLDER` を実ドメインに置換：

```bash
ssh muy
cd /home/ec2-user/muybien
sed -i 's/DOMAIN_PLACEHOLDER/yourdomain.com/g' nginx/conf.d/production.conf
```

または、デプロイ時に環境変数で指定：

```bash
PROD_DOMAIN=yourdomain.com make prod-deploy
```

---

## 🔄 4. デプロイ（通常運用）

ローカルのプロジェクトルートから：

```bash
make prod-deploy
# または
./scripts/deploy.sh
```

`deploy.sh` の処理内容：

1. SSH 接続テスト（`muy`）
2. フロントエンドビルド（`npm run build` → `myapp-web/app/dist/`）
3. rsync でサーバーへファイル転送
4. サーバー上で `scripts/deploy_lightsail.sh` を実行
5. `docker compose -f docker-compose.prod.yml up --build -d`

### デプロイ後の確認

```bash
ssh muy 'cd /home/ec2-user/muybien && docker compose -f docker-compose.prod.yml ps'
make prod-logs
```

---

## 🌐 5. ドメインの設定

### 5.1 DNS レコードの追加

DNS プロバイダー（お名前.com、Route 53 等）で以下を設定：

```
Type: A
Name: @
Value: YOUR_LIGHTSAIL_IP
TTL: 3600

Type: A
Name: www
Value: YOUR_LIGHTSAIL_IP
TTL: 3600
```

反映確認：

```bash
dig +short yourdomain.com A
```

### 5.2 SSL 証明書

[SSL_SETUP.md](SSL_SETUP.md) を参照して Let's Encrypt を設定。

---

## 🛠 6. 運用コマンド

| コマンド | 説明 |
|---------|------|
| `make prod-deploy` | デプロイ（ビルド + 転送 + 起動） |
| `make prod-logs` | 本番ログ（tail -f） |
| `make prod-migrate` | 本番マイグレーション |
| `make prod-bash` | 本番 API コンテナシェル |
| `make prod-down` | 本番コンテナ停止 |

サーバー上で直接操作する場合：

```bash
cd /home/ec2-user/muybien
docker compose -f docker-compose.prod.yml logs --tail=50 myapp-api
docker compose -f docker-compose.prod.yml restart myapp-api
docker exec muybien-api python manage.py createsuperuser
```

---

## 🔍 7. トラブルシューティング

### SSH 接続できない

```bash
# 鍵の権限確認
chmod 400 ~/.ssh/your-key.pem

# 接続テスト
ssh -vvv muy
```

Lightsail コンソールでポート 22（SSH）が開いているか確認。

### デプロイ後にサイトが表示されない

```bash
ssh muy 'cd /home/ec2-user/muybien && docker compose -f docker-compose.prod.yml ps'
ssh muy 'docker logs muybien-nginx --tail=30'
ssh muy 'docker logs muybien-api --tail=30'
```

- コンテナが `Exited` ならログを確認
- `.env.prod` が存在するか確認
- ファイアウォールで 80/443（または 8090/8453）が開いているか確認 → [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md)

### 502 Bad Gateway

```bash
ssh muy 'docker compose -f docker-compose.prod.yml restart myapp-api'
ssh muy 'docker logs muybien-api --tail=50'
```

API コンテナの起動失敗（DB 接続エラー、SECRET_KEY 未設定等）が多い原因です。

### フロントの変更が反映されない

デプロイ前に `npm run build` が実行されているか確認。`make prod-deploy` は自動でビルドします。

---

## 💰 コスト見積もり

| サービス | 月額コスト |
|---------|-----------|
| Lightsail (1GB) | $5.00 |
| データ転送 (2TB 含む) | $0.00 |
| **合計** | **$5.00/月〜** |

※ SSL 証明書（Let's Encrypt）は無料。SES は送信量に応じて課金。

---

## ✅ チェックリスト

デプロイ前の確認事項：

- [ ] Lightsail インスタンスが起動している
- [ ] 静的 IP アドレスが割り当てられている
- [ ] SSH 接続ができる（`ssh muy`）
- [ ] `setup_lightsail.sh` を実行済み
- [ ] `.env.prod` が正しく設定されている
- [ ] nginx の `DOMAIN_PLACEHOLDER` を置換済み（または `PROD_DOMAIN` 指定）
- [ ] DNS の A レコードが Lightsail IP を向いている
- [ ] SSL 証明書が設定されている（HTTPS 利用時）
- [ ] Lightsail ファイアウォールで必要ポートが開いている

---

## 📚 関連ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [PRODUCTION.md](PRODUCTION.md) | 本番環境変数 |
| [SSL_SETUP.md](SSL_SETUP.md) | HTTPS 設定 |
| [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) | ネットワーク |
| [DOCUMENTATION.md](DOCUMENTATION.md) | 索引 |
