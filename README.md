# MuyBien

永井謙史のポートフォリオ・サービス紹介サイト。  
Django REST API + Vue 3 SPA 構成。**スタイルは Tailwind CSS 4**（ユーティリティクラス）。主な機能はコンタクトフォーム（メール通知付き）。

## 📚 ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| **[DOCUMENTATION.md](DOCUMENTATION.md)** | **全 Markdown の索引**（目的別・読む順） |
| **[PRODUCTION.md](PRODUCTION.md)** | **本番環境の設定**（環境変数、SES、migrate 等） |
| [DEPLOYMENT.md](DEPLOYMENT.md) | AWS Lightsail デプロイ手順 |
| [SSL_SETUP.md](SSL_SETUP.md) | Let's Encrypt 等の SSL |
| [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) | Lightsail ネットワーク設定 |

---

## システム構成

### 概要

```
[ブラウザ]
    │
    ▼
[Nginx] ── / ──────────────► Vue SPA（静的ファイル: dist/）
    │
    └── /v1/api/ ──────────► Django + Gunicorn（:8000）
                                    │
                                    ▼
                              [PostgreSQL 16.2]
```

### ローカル開発

| コンポーネント | 技術 | ポート |
|--------------|------|--------|
| フロント | Vue 3 + TypeScript + Vite 5 + Tailwind CSS 4 | 5173 |
| API | Django 4.2 + DRF | 8000 |
| DB | PostgreSQL 16.2 | 15433（ホスト側） |

- フロント → API は Vite の dev proxy（`/v1/api` → `http://myapp-api:8000`）
- 公開 API（コンタクト）は認証なし（AllowAny）。管理者用の「永井のLab」は JWT 認証

### フロントエンド・スタイリング

CSS フレームワークは **Tailwind CSS 4** を使用。Vue コンポーネントの `class` 属性にユーティリティクラスを直接記述する方式（別途 `.scss` / CSS Modules は使わない）。

| 項目 | ファイル・パス |
|------|---------------|
| Tailwind エントリ | `myapp-web/app/src/assets/main.css`（`@import "tailwindcss"`） |
| テーマ変数（色・フォント） | 同ファイルの `@theme { ... }` |
| Vite プラグイン | `myapp-web/app/vite.config.ts`（`@tailwindcss/vite`） |
| クラス結合ヘルパ | `myapp-web/app/src/lib/utils.ts`（`cn()` = clsx + tailwind-merge） |
| UI コンポーネント | `radix-vue`（アクセシブルな headless UI） |

```vue
<!-- 例: HomeView.vue -->
<section class="relative min-h-screen flex items-center bg-[#080c14]">
  <h1 class="text-5xl font-black text-white">...</h1>
</section>
```

### 本番（Lightsail）

| コンポーネント | 技術 | 備考 |
|--------------|------|------|
| リバースプロキシ | Nginx（Docker コンテナ） | SSL 終端、SPA 配信 |
| API | Django + Gunicorn（Docker コンテナ） | migrate / collectstatic 自動実行 |
| DB | PostgreSQL 16.2（Docker コンテナ） | ボリューム永続化 |
| フロント | Vue SPA（ビルド済み `dist/`） | デプロイ前にローカルで `npm run build` |

- デプロイ方式: ローカルから **rsync** + **docker compose**
- SSH エイリアス: `muy`（ユーザー: `ec2-user`）
- デプロイ先: `/home/ec2-user/muybien`

### ディレクトリ構成

```
MuyBienBase/
├── myapp-api/django/     # Django バックエンド
│   ├── contact/          # コンタクトフォーム API
│   ├── lab/              # 管理者用 Lab API（JWT）
│   └── core/settings/    # 設定（local / production）
├── myapp-web/app/        # Vue 3 フロントエンド
├── nginx/conf.d/         # Nginx 設定（local / production）
├── scripts/              # デプロイスクリプト
├── docker-compose.yml    # ローカル開発用
├── docker-compose.prod.yml  # 本番用
├── env.prod.example      # 本番環境変数テンプレート
└── Makefile              # 開発・デプロイコマンド
```

---

## 機能

| ページ | パス | 説明 |
|--------|------|------|
| ホーム | `/` | トップページ |
| サービス | `/services` | サービス紹介 |
| ポートフォリオ | `/portfolio` | 実績紹介 |
| プロフィール | `/profile` | プロフィール |
| お問い合わせ | `/contact` | コンタクトフォーム |
| 永井のLab（ログイン） | `/lab/login` | 管理者ログイン（JWT） |
| 永井のLab | `/lab` | お問い合わせ一覧（要ログイン） |

### 永井のLab（管理者ログイン）

公開サイトとは別に、お問い合わせ内容を確認する **管理者 UI** があります。

| 項目 | 内容 |
|------|------|
| 認証方式 | JWT（Django スーパーユーザー） |
| ログイン画面 | `/lab/login` |
| ダッシュボード | `/lab`（お問い合わせ一覧） |
| 用途 | コンタクトフォームの受信内容確認 |

**初回はスーパーユーザー作成が必要です。**

```bash
# ローカル
make createsuperuser

# 本番
make prod-createsuperuser
# または
ssh muy
cd /home/ec2-user/muybien
sudo docker exec -it muybien-api python manage.py createsuperuser
```

本番 URL 例: `https://muybien.jp/lab/login`  
詳細（本番作業）は [PRODUCTION.md](PRODUCTION.md) の「スーパーユーザー / 永井のLab」を参照。

### API

| Method | Path | 説明 |
|--------|------|------|
| POST | `/v1/api/contact` | お問い合わせ送信（DB 保存 + メール通知） |
| POST | `/v1/api/auth/login` | Lab ログイン（JWT 取得） |
| POST | `/v1/api/auth/refresh` | JWT リフレッシュ |
| GET | `/v1/api/auth/me` | ログイン中ユーザー情報 |
| GET | `/v1/api/lab/contacts` | お問い合わせ一覧（要認証） |
| GET | `/v1/api/lab/contacts/<id>` | お問い合わせ詳細（要認証） |

※ trailing_slash なし。

---

## ローカル開発

### 前提条件

- Docker / Docker Compose
- （フロント単体開発時）Node.js 20+

### 起動

```bash
make up        # コンテナ起動
make logs      # ログ確認
make down      # 停止
```

### アクセス

| 用途 | URL |
|------|-----|
| フロント | http://localhost:5173 |
| Lab ログイン | http://localhost:5173/lab/login |
| API | http://localhost:8000/v1/api/contact |
| Django Admin | http://localhost:8000/admin/ |

### よく使うコマンド

```bash
make migrate           # マイグレーション適用
make makemigrations    # マイグレーションファイル生成
make createsuperuser   # 管理ユーザー作成
make api-bash          # API コンテナ内シェル
make web-bash          # フロントコンテナ内シェル
make build-front       # フロントのプロダクションビルド
```

---

## 本番デプロイ（概要）

詳細は [DEPLOYMENT.md](DEPLOYMENT.md) を参照。

```bash
# 初回: サーバーで setup_lightsail.sh を実行後
make prod-deploy            # ビルド + rsync + docker compose up
make prod-logs              # 本番ログ
make prod-migrate           # 本番マイグレーション
make prod-createsuperuser   # 本番スーパーユーザー作成（Lab / Admin 用）
make prod-bash              # 本番 API シェル
make prod-down              # 本番停止
```

⚠️ **本番 DB のリセットは絶対に行わないこと。**

---

## 技術スタック

| レイヤ | 技術 |
|--------|------|
| Backend | Django 4.2, Django REST Framework |
| Frontend | Vue 3, TypeScript, Vite 5 |
| CSS | **Tailwind CSS 4**（`@tailwindcss/vite`、ユーティリティファースト） |
| UI | radix-vue, lucide-vue-next |
| Database | PostgreSQL 16.2 |
| 本番 WSGI | Gunicorn |
| 本番 Proxy | Nginx |
| メール（本番） | AWS SES（SMTP） |
| インフラ | AWS Lightsail + Docker Compose |
