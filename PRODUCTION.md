# 本番環境の設定

Django アプリ（`core/settings/`）が参照する **環境変数** と、本番で必要な **付帯作業** をまとめています。デプロイ手順そのものは [DEPLOYMENT.md](DEPLOYMENT.md) を参照してください。

---

## 前提

- 本番では **`DEBUG=False`**（`core/settings/environments/production.py` で固定）。
- 秘密情報（`SECRET_KEY`、DB パスワード、SES 認証情報など）は **リポジトリに含めず**、サーバの `.env.prod` で管理する。
- `.env.prod` は `docker-compose.prod.yml` の `env_file` 経由でコンテナに渡される。
- `.env.prod` は `.gitignore` 対象。**コミットしない。**

---

## 環境変数一覧

設定ファイルのテンプレート: `env.prod.example`

### 必須（本番）

| 変数名 | 説明 | 例・備考 |
|--------|------|----------|
| `SECRET_KEY` | Django の署名・暗号化用 | `setup_lightsail.sh` で自動生成可 |
| `ALLOWED_HOSTS` | 許可するホスト（カンマ区切り） | `yourdomain.com,www.yourdomain.com` |
| `RDS_DB_NAME` | PostgreSQL DB 名 | `muybiendb` |
| `RDS_USERNAME` | DB ユーザー | `postgres` |
| `RDS_PASSWORD` | DB パスワード | 強力なランダム文字列 |
| `RDS_HOSTNAME` | DB ホスト | `myapp-db`（Docker 内部名） |
| `RDS_PORT` | DB ポート | `5432` |
| `POSTGRES_DB` | Docker DB コンテナ用 DB 名 | `RDS_DB_NAME` と同じ値 |
| `POSTGRES_USER` | Docker DB コンテナ用ユーザー | `RDS_USERNAME` と同じ値 |
| `POSTGRES_PASSWORD` | Docker DB コンテナ用パスワード | `RDS_PASSWORD` と同じ値 |

### CORS

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `CORS_ALLOWED_ORIGINS` | 許可するフロントオリジン（カンマ区切り） | `https://yourdomain.com,https://www.yourdomain.com` |

### メール送信（AWS SES）

本番ではコンタクトフォーム通知に **Amazon SES の SMTP エンドポイント** を使用します。

| 変数名 | 説明 |
|--------|------|
| `EMAIL_BACKEND` | `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | `email-smtp.ap-northeast-1.amazonaws.com`（リージョンに合わせる） |
| `EMAIL_PORT` | `587` |
| `EMAIL_USE_TLS` | `True` |
| `EMAIL_USE_SSL` | `False` |
| `EMAIL_HOST_USER` | SES の SMTP ユーザー名 |
| `EMAIL_HOST_PASSWORD` | SES の SMTP パスワード |
| `DEFAULT_FROM_EMAIL` | 送信元（SES で検証済みのアドレス） |
| `CONTACT_NOTIFY_EMAIL` | お問い合わせ通知先 |

#### SES 設定手順（概要）

1. **SES を有効化**し、送信元ドメインまたはメールアドレスを **検証**
2. 初期は **サンドボックス**のため、検証済みアドレスにしか送れない → 本番向けに **本番アクセス（サンドボックス解除）** を申請
3. SES コンソールで **SMTP 認証情報を作成**（IAM アクセスキーとは別物）
4. `DEFAULT_FROM_EMAIL` は **検証済みドメイン**のアドレスに合わせる

詳細: AWS 公式「[SMTP 経由で Amazon SES に接続する](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html)」

---

## Django / アプリ固有の本番作業

### 1. マイグレーション

`docker-compose.prod.yml` の起動コマンドに `migrate` が含まれているため、通常デプロイ時に自動実行されます。

手動実行：

```bash
make prod-migrate
# または
ssh pfweb 'docker exec muybien-api python manage.py migrate --noinput'
```

⚠️ **本番 DB のリセット（`flush`、ボリューム削除等）は絶対に行わないこと。**

### 2. 静的ファイル

`collectstatic` も起動コマンドに含まれています。Nginx が `/static/` を配信します。

### 3. スーパーユーザー作成

```bash
ssh pfweb 'docker exec -it muybien-api python manage.py createsuperuser'
```

管理画面: `https://yourdomain.com/admin/`

### 4. 環境変数変更後

`.env.prod` を変更したあとは API コンテナを再起動：

```bash
ssh pfweb 'cd /home/ubuntu/muybien && docker compose -f docker-compose.prod.yml restart myapp-api'
```

---

## 本番コンテナ構成

`docker-compose.prod.yml` で以下 3 サービスが起動します：

| サービス | コンテナ名 | 役割 |
|---------|-----------|------|
| nginx | muybien-nginx | リバースプロキシ + SPA 配信 + SSL |
| myapp-api | muybien-api | Django + Gunicorn |
| myapp-db | muybien-db | PostgreSQL |

### ポートマッピング（デフォルト）

| ホスト | コンテナ | 用途 |
|--------|---------|------|
| 8090 | 80 | HTTP（→ HTTPS リダイレクト） |
| 8453 | 443 | HTTPS |

専用サーバーで標準ポートを使う場合は `docker-compose.prod.yml` を `80:80` / `443:443` に変更してください。詳細は [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md)。

---

## `.env.prod` 記述例（本番・イメージ）

実際の値は置き換えること。**このブロックをそのままコミットしない。**

```env
SECRET_KEY=（十分に長いランダム文字列）
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com

RDS_DB_NAME=muybiendb
RDS_USERNAME=postgres
RDS_PASSWORD=（強力なパスワード）
RDS_HOSTNAME=myapp-db
RDS_PORT=5432

POSTGRES_DB=muybiendb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=（RDS_PASSWORD と同じ）

CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=email-smtp.ap-northeast-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=（SES SMTP ユーザー名）
EMAIL_HOST_PASSWORD=（SES SMTP パスワード）
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL=noreply@yourdomain.com
CONTACT_NOTIFY_EMAIL=kenji.nagai@globalway.co.jp
```

---

## 関連ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [DOCUMENTATION.md](DOCUMENTATION.md) | 索引 |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Lightsail デプロイ |
| [SSL_SETUP.md](SSL_SETUP.md) | HTTPS |
| [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) | ネットワーク |
