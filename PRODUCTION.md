# 本番環境の設定

Django アプリ（`core/settings/`）が参照する **環境変数** と、本番で必要な **付帯作業** をまとめています。デプロイ手順そのものは [DEPLOYMENT.md](DEPLOYMENT.md) を参照してください。

---

## 前提

- 本番では **`DEBUG=False`**（`core/settings/environments/production.py` で固定）。
- 秘密情報（`SECRET_KEY`、DB パスワード、SES 認証情報など）は **リポジトリに含めず**、サーバの `.env.prod` で管理する。
- `.env.prod` は `docker-compose.prod.yml` の `env_file` 経由でコンテナに渡される。
- `.env.prod` は `.gitignore` 対象。**コミットしない。**
- 本番サーバー（Amazon Linux）では `ec2-user` が **docker グループに未所属** のことがあり、`docker` コマンドには **`sudo`** が必要です（例: `sudo docker exec ...`）。

---

## `.env.prod` と `make prod-deploy` の関係

よくある誤解: **ローカルの `.env.prod` を編集して `make prod-deploy` しても、本番には反映されません。**

| 操作 | `.env.prod` は反映される？ |
|------|---------------------------|
| ローカルで `.env.prod` を編集 → `make prod-deploy` | ❌ **反映されない**（rsync で転送しない） |
| **サーバー上**で `.env.prod` を編集 → `make prod-deploy` | ✅ **反映される**（`docker compose up -d` でコンテナ再作成時に読み込む） |
| サーバー上で `.env.prod` を編集 → `docker compose restart` のみ | ❌ **反映されない**（起動時の環境変数がそのまま） |
| サーバー上で `.env.prod` を編集 → `docker compose up -d myapp-api` | ✅ **反映される** |

### 仕組み

```
[ローカル PC]                         [本番サーバー /home/ec2-user/muybien/]
  env.prod.example  ──参考用──►          .env.prod  ← ここだけが本番の正
  .env.prod（あっても）                  ↑
       │                                 │ docker-compose.prod.yml の env_file
       └── rsync 除外 ──転送されない ──►  myapp-api / myapp-db コンテナ
```

`make prod-deploy` がやること:

1. フロントをビルド
2. **コード**を rsync で転送（`.env.prod` は **除外**）
3. サーバーで `docker compose up --build -d` → その時点の **サーバー上の `.env.prod`** を読んでコンテナ起動

### `.env.prod` を変更したときの手順

**必ずサーバー上のファイルを編集**してください。

```bash
ssh muy
nano /home/ec2-user/muybien/.env.prod
# 保存後、コンテナを再作成（restart だけでは不可）
cd /home/ec2-user/muybien
sudo docker compose -f docker-compose.prod.yml up -d myapp-api
```

またはローカルから:

```bash
make prod-deploy   # コード変更と一緒にデプロイする場合（up -d も実行される）
```

### 現在の設定を確認する

ファイルとコンテナ内の値が一致しているか:

```bash
ssh muy 'grep DEFAULT_FROM_EMAIL /home/ec2-user/muybien/.env.prod'
ssh muy 'sudo docker exec muybien-api python manage.py shell -c "from django.conf import settings; print(settings.DEFAULT_FROM_EMAIL)"'
```

両方の出力が同じなら `.env.prod` は正しく読み込まれています。

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

本番ではコンタクトフォーム通知に **Amazon SES（Simple Email Service）の SMTP エンドポイント** を使用します。

Django は SMTP クライアントとして SES に接続し、お問い合わせ内容を `CONTACT_NOTIFY_EMAIL` へ送信します。

| 変数名 | 説明 | 設定例（MuyBien） |
|--------|------|-------------------|
| `EMAIL_BACKEND` | Django のメールバックエンド | `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | SES の SMTP エンドポイント（**リージョンごとに固定**） | `email-smtp.ap-northeast-1.amazonaws.com` |
| `EMAIL_PORT` | SMTP ポート（STARTTLS） | `587` |
| `EMAIL_USE_TLS` | STARTTLS を使う | `True` |
| `EMAIL_USE_SSL` | SMTPS（465）を使う場合のみ `True` | `False` |
| `EMAIL_HOST_USER` | **SES で作成した SMTP ユーザー名** | `AKIAxxxxxxxxxxxx` 形式 |
| `EMAIL_HOST_PASSWORD` | **SES で作成した SMTP パスワード** | 作成時に一度だけ表示される文字列 |
| `DEFAULT_FROM_EMAIL` | 送信元（**SES で検証済み**のアドレス） | `noreply@muybien.jp` |
| `CONTACT_NOTIFY_EMAIL` | お問い合わせ通知先 | `kenji.nagai@globalway.co.jp` |

> **重要**: `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` は **IAM の通常アクセスキー（コンソールログイン用）とは別物** です。  
> AWS SES コンソールの「SMTP 認証情報を作成」から発行する **SES 専用の SMTP 資格情報** を `.env.prod` に設定します。

---

#### SES 設定の全体像

```
[コンタクトフォーム]
       │
       ▼
[Django / muybien-api] ──SMTP(587/TLS)──► [Amazon SES ap-northeast-1]
       │                                        │
       │                                        ▼
       └──────────────────────────────► [CONTACT_NOTIFY_EMAIL へ配信]
```

1. SES で **送信元ドメイン**（`muybien.jp`）を検証する
2. （必要なら）**サンドボックス解除**を申請する
3. SES コンソールで **SMTP 認証情報** を作成する
4. サーバの `.env.prod` に反映し、API コンテナを再起動する

---

#### 手順 1: AWS リージョンを確認する

SES は **リージョン単位** で設定します。Lightsail インスタンスが東京なら **`ap-northeast-1`（アジアパシフィック・東京）** を使います。

1. [AWS マネジメントコンソール](https://console.aws.amazon.com/) にログイン
2. 右上のリージョンを **「アジアパシフィック（東京）ap-northeast-1」** に変更
3. サービス検索で **「Amazon SES」**（Simple Email Service）を開く

> `EMAIL_HOST` はこのリージョンに合わせる必要があります。  
> 東京: `email-smtp.ap-northeast-1.amazonaws.com`  
> 一覧: [AWS SES SMTP エンドポイント](https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html)

---

#### 手順 2: 送信元ドメインを検証する

`DEFAULT_FROM_EMAIL`（例: `noreply@muybien.jp`）から送るには、**ドメインまたはメールアドレスの所有者確認** が必要です。ドメイン単位の検証を推奨します。

1. SES コンソール左メニュー → **Identities（ID）** → **Create identity（ID を作成）**
2. **Identity type**: **Domain** を選択
3. **Domain**: `muybien.jp` を入力
4. （推奨）**Easy DKIM** を有効のまま → **Create identity**

**DNS レコードの追加（ムームードメイン / dnsv.jp 利用時）**

SES に表示される **CNAME レコード（DKIM 用 3 件）** を、ドメインの DNS 管理画面に追加します。

| 種別 | 名前（ホスト） | 値 |
|------|---------------|-----|
| CNAME | SES が表示する `xxxx._domainkey.muybien.jp` | SES が表示する値 |

追加後、SES の Identities 画面で `muybien.jp` の **Verification status** が **Verified（検証済み）** になるまで待ちます（数分〜最大 72 時間）。

**SPF（任意だが推奨）**

DNS に TXT レコードを追加：

```
v=spf1 include:amazonses.com ~all
```

---

#### 手順 3: サンドボックス解除（本番運用に必須）

SES は初期状態 **サンドボックス** です。サンドボックス中は次の制限があります。

- **検証済みアドレスにしか送れない**（任意のお客様アドレスへは送れない）
- 送信量に上限あり

コンタクトフォームは **検証済みの `CONTACT_NOTIFY_EMAIL` へ通知** するだけなら、サンドボックスでも動作します。  
ただし将来の拡張や運用安定のため、**本番アクセス（Production access）の申請** を推奨します。

1. SES コンソール左メニュー → **Account dashboard（アカウントダッシュボード）**
2. **Sending limits** 付近の **Request production access（本番アクセスをリクエスト）** をクリック
3. フォーム入力例：
   - **Mail type**: Transactional
   - **Website URL**: `https://muybien.jp`
   - **Use case**: ポートフォリオサイトのお問い合わせフォームからの通知メール
4. 送信 → 通常 **24 時間以内** に AWS から承認メール

---

#### 手順 4: SMTP 認証情報を作成する（ここが `.env.prod` に入る値）

**はい、SMTP 認証情報は AWS SES コンソールで作成します。** IAM ユーザーのアクセスキーをそのまま使うのではなく、SES 専用の SMTP 資格情報を発行します。

1. SES コンソール左メニュー → **SMTP settings（SMTP 設定）**
2. **Create SMTP credentials（SMTP 認証情報を作成）** をクリック
3. **IAM ユーザー名**（自動生成で可）を確認 → **Create user（ユーザーを作成）**
4. 表示される **SMTP username** と **SMTP password** を **必ず控える**
   - パスワードは **この画面でしか表示されません**（再表示不可）
   - 紛失した場合は **新しい SMTP 認証情報を作り直す**

控えた値の対応：

| SES コンソールに表示 | `.env.prod` の変数 |
|---------------------|-------------------|
| SMTP username | `EMAIL_HOST_USER` |
| SMTP password | `EMAIL_HOST_PASSWORD` |

> 裏側では SES 用の IAM ユーザーが自動作成されますが、Django に設定するのは **SMTP username / password** です。  
> IAM アクセスキー ID / シークレットキーを直接 `.env.prod` に書く必要はありません。

---

#### 手順 5: `.env.prod` に反映する

サーバー上で編集：

```bash
ssh muy
nano /home/ec2-user/muybien/.env.prod
```

メール関連を次のように設定（値は実際の SMTP 認証情報に置き換え）：

```env
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=email-smtp.ap-northeast-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=AKIAxxxxxxxxxxxxxxxx
EMAIL_HOST_PASSWORD=（SES で表示された SMTP パスワード）
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL=noreply@muybien.jp
CONTACT_NOTIFY_EMAIL=kenji.nagai@globalway.co.jp
```

反映（**`restart` だけでは `.env.prod` は再読み込みされません**。コンテナを再作成してください）：

```bash
ssh muy 'cd /home/ec2-user/muybien && sudo docker compose -f docker-compose.prod.yml up -d myapp-api'
```

---

#### 手順 6: 送信テスト

**方法 A: Django shell から**

```bash
ssh muy 'sudo docker exec muybien-api python manage.py shell -c "
from django.core.mail import send_mail
from django.conf import settings
send_mail(
    subject=\"[MuyBien] SES テスト\",
    message=\"SMTP 設定のテストメールです。\",
    from_email=settings.DEFAULT_FROM_EMAIL,
    recipient_list=[settings.CONTACT_NOTIFY_EMAIL],
    fail_silently=False,
)
print(\"sent to\", settings.CONTACT_NOTIFY_EMAIL)
"'
```

**方法 B: 本番サイトのコンタクトフォームから送信**

https://muybien.jp/contact からテスト送信し、`CONTACT_NOTIFY_EMAIL` に届くか確認。

**方法 C: API 直接（curl）**

```bash
curl -s -X POST https://muybien.jp/v1/api/contact \
  -H "Content-Type: application/json" \
  -d '{"name":"テスト","email":"test@example.com","message":"SES動作確認"}'
```

---

#### よくあるエラーと対処

| 症状 | 原因 | 対処 |
|------|------|------|
| `Authentication Credentials Invalid` | SMTP ユーザー名/パスワードが誤り | SES で SMTP 認証情報を再作成し `.env.prod` を更新 |
| `Email address is not verified` | サンドボックス中に未検証アドレスへ送信 | 送信先を SES で検証するか、本番アクセス申請 |
| `Message rejected: Email address is not verified`（From） | `DEFAULT_FROM_EMAIL` が未検証 | `muybien.jp` ドメイン検証 + From を `@muybien.jp` に |
| 接続タイムアウト | `EMAIL_HOST` のリージョン不一致 | `ap-northeast-1` 用エンドポイントか確認 |
| メールが届かない（エラーなし） | 迷惑メールフォルダ / SPF 未設定 | SPF 追加、SES の送信統計・バウンスを確認 |

ログ確認：

```bash
make prod-logs
# または
ssh muy 'sudo docker logs muybien-api --tail=50'
```

---

#### 参考リンク

- [SMTP 経由で Amazon SES に接続する（AWS 公式）](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html)
- [SES SMTP エンドポイント一覧](https://docs.aws.amazon.com/ses/latest/dg/smtp-connect.html)
- [サンドボックスからの移行（本番アクセス）](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)

---

## Django / アプリ固有の本番作業

### 1. マイグレーション

`docker-compose.prod.yml` の起動コマンドに `migrate` が含まれているため、通常デプロイ時に自動実行されます。

手動実行：

```bash
make prod-migrate
# または
ssh muy 'sudo docker exec muybien-api python manage.py migrate --noinput'
```

⚠️ **本番 DB のリセット（`flush`、ボリューム削除等）は絶対に行わないこと。**

### 2. 静的ファイル

`collectstatic` も起動コマンドに含まれています。Nginx が `/static/` を配信します。

### 3. スーパーユーザー作成

```bash
ssh muy 'sudo docker exec -it muybien-api python manage.py createsuperuser'
```

管理画面: `https://muybien.jp/admin/`

### 4. 環境変数変更後

`.env.prod` を変更したあとは API コンテナを **再作成**（`up -d`）。`restart` では環境変数は更新されません。

```bash
ssh muy 'cd /home/ec2-user/muybien && sudo docker compose -f docker-compose.prod.yml up -d myapp-api'
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
ALLOWED_HOSTS=muybien.jp,www.muybien.jp,57.182.190.160,localhost

RDS_DB_NAME=muybiendb
RDS_USERNAME=postgres
RDS_PASSWORD=（強力なパスワード）
RDS_HOSTNAME=myapp-db
RDS_PORT=5432

POSTGRES_DB=muybiendb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=（RDS_PASSWORD と同じ）

CORS_ALLOWED_ORIGINS=https://muybien.jp,https://www.muybien.jp

EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=email-smtp.ap-northeast-1.amazonaws.com
EMAIL_PORT=587
EMAIL_HOST_USER=AKIAxxxxxxxxxxxxxxxx
EMAIL_HOST_PASSWORD=（SES コンソール「SMTP 認証情報を作成」で表示されたパスワード）
EMAIL_USE_TLS=True
EMAIL_USE_SSL=False
DEFAULT_FROM_EMAIL=noreply@muybien.jp
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
