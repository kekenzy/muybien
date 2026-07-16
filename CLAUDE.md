# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

---

## Project Overview

**MuyBien** — 永井謙史のポートフォリオ・サービス紹介サイト。
Django REST API + Vue 3 SPA 構成。**CSS は Tailwind CSS 4**（scoped CSS / SCSS は使わず、テンプレートにユーティリティクラスを記述）。主な機能はコンタクトフォーム（メール通知付き）。

---

## Architecture

**Backend (`myapp-api/django/`)**
- Django 4.2 + DRF, PostgreSQL 16.2
- 公開 API（`contact/`）は認証なし（AllowAny）。管理者用 `lab/` は JWT
- アプリは `contact/` + `lab/`
- 設定: `core/settings/common.py` + `core/settings/environments/{local,production}.py`
- メール: ローカルはコンソール出力 / 本番は AWS SES
- ログ: `log/app.log`

**Frontend (`myapp-web/app/src/`)**
- Vue 3 + TypeScript + Vite 5
- **Tailwind CSS 4** — `@tailwindcss/vite` プラグイン、`src/assets/main.css` で `@import "tailwindcss"`
- テーマカラー等は `main.css` の `@theme { }` で定義（`--color-primary` 等）
- 条件付きクラス結合は `src/lib/utils.ts` の `cn()` を使う
- UI: `radix-vue` + `lucide-vue-next`（Tailwind で見た目を当てる）
- ルーター: `/`, `/services`, `/portfolio`, `/profile`, `/contact`, `/lab`, `/lab/login`
- axios で `/v1/api/` へリクエスト（Vite proxy 経由）

**フロントのスタイル方針**
- 新規スタイルは **Tailwind ユーティリティクラス** を優先（`<style scoped>` は原則使わない）
- グローバルな CSS 追加が必要な場合のみ `src/assets/main.css` を編集

**Nginx** (本番のみ) — 80→443リダイレクト、SSL (Let's Encrypt)、
`/v1/api/` → Django (8000)、`/` → Vue SPA。

---

## API Endpoints

| Method | Path | 説明 |
|--------|------|------|
| POST | `/v1/api/contact` | コンタクトフォーム送信（メール通知・DB保存） |
| POST | `/v1/api/auth/login` | Lab ログイン（JWT） |
| POST | `/v1/api/auth/refresh` | JWT リフレッシュ |
| GET | `/v1/api/auth/me` | ログイン中ユーザー（権限情報を含む） |
| POST | `/v1/api/lab/set-password` | 招待メールのリンクから初回パスワード設定（未認証） |
| GET | `/v1/api/lab/contacts` | お問い合わせ一覧（要認証） |
| GET | `/v1/api/lab/contacts/<id>` | お問い合わせ詳細（要認証） |
| GET/POST | `/v1/api/lab/customers` | 顧客管理 |
| POST | `/v1/api/lab/customers/<id>/invite` | 顧客をLabログインユーザーとして招待 |
| GET/POST | `/v1/api/lab/users` | ユーザー管理（Django User） |
| GET/POST | `/v1/api/lab/roles` | 権限管理（ロール・メニュー権限・メンバー） |

※ DRF Router は使わず直接 `path()` 登録。trailing_slash なし。

**永井のLab**: `/lab/login` → JWTでログイン → `/lab` でお問い合わせ一覧。詳細は [README.md](README.md)。

### Lab の権限管理（RBAC）

Labは「権限管理」画面でロールを作成し、ロールごとに各メニューへの権限（`0`=なし / `1`=参照 / `2`=参照・編集）を設定する（walinkの`RoleMenuPermission`と同じ考え方）。`is_superuser`・`is_staff`は常に全メニューにフルアクセス。ユーザーは複数ロールを持てて、メニューごとに最も強い権限が採用される。

**新しいLabメニューを追加するときは、必ず以下を同時に更新すること**（片方だけだと権限が機能しない）:
1. バックエンド: `myapp-api/django/lab/models.py` の `MENU_CHOICES` に `('menu_key', '画面名')` を追加
2. バックエンド: 該当ViewSetに `menu_key = 'menu_key'` と `permission_classes = [IsAuthenticated, MenuPermission]` を設定（`lab/permissions.py`）
3. フロント: `myapp-web/app/src/router/index.ts` のルート `meta.menuKey` と `LAB_MENU_ROUTES`
4. フロント: `myapp-web/app/src/layouts/LabLayout.vue` の `allNavItems`（`canRead`でフィルタされる）
5. フロント: 画面内の作成・編集・削除ボタンは `canWrite('menu_key')` で出し分ける（`src/lib/permissions.ts`）

顧客をLabにログインさせたい場合は、顧客管理の詳細から「Labへ招待」ボタンでユーザーを発行し、招待メール（パスワード設定リンク）を送信する。

---

## Common Development Commands (run from `MuyBienBase/`)

```bash
make up              # コンテナ起動
make down            # コンテナ停止
make restart         # コンテナ再起動
make docker-reflesh  # 未使用の Docker イメージ・ビルドキャッシュを削除（ボリュームは残す）
make logs            # 全コンテナログ
make api-logs        # API ログ
make api-bash        # API コンテナ内シェル
make web-bash        # フロントコンテナ内シェル
make migrate         # マイグレーション適用
make makemigrations  # マイグレーションファイル生成
make createsuperuser # スーパーユーザー作成（Lab / Admin 用）
make build-front     # フロントのプロダクションビルド
```

**Access**:
- フロント: `http://localhost:5173`
- Lab ログイン: `http://localhost:5173/lab/login`
- API: `http://localhost:8000/v1/api/contact`
- Django Admin: `http://localhost:8000/admin/`
- Mailpit（ローカル送信メール確認）: `http://localhost:8025`

---

## Production Deployment

- サーバー: AWS EC2 (SSH alias: `muy`, ユーザー: `ec2-user`)
- デプロイ先: `/home/ec2-user/muybien`
- **詳細ドキュメント**: [DOCUMENTATION.md](DOCUMENTATION.md) → [DEPLOYMENT.md](DEPLOYMENT.md)

```bash
make prod-deploy            # ビルド + rsync + docker-compose up（本番）
make prod-logs              # 本番ログ
make prod-migrate           # 本番マイグレーション
make prod-createsuperuser   # 本番スーパーユーザー作成（Lab / Admin）
make prod-bash              # 本番APIコンテナシェル
make prod-down              # 本番停止
```

⚠️ **本番 DB のリセットは絶対に行わないこと。**

---

## Adding a New Feature

1. **バックエンド追加**: `contact/` を参考にモデル・ビュー・URL を追加
2. **マイグレーション**: `make makemigrations && make migrate`
3. **フロント追加**: `views/` にコンポーネント追加、`router/index.ts` にルート登録（スタイルは Tailwind クラスで記述）

---

## Environment Variables

| 変数 | 説明 |
|------|------|
| `DJANGO_SETTINGS_MODULE` | 設定モジュールパス |
| `SECRET_KEY` | Django シークレットキー（本番必須） |
| `RDS_*` | PostgreSQL 接続情報 |
| `CONTACT_NOTIFY_EMAIL` | コンタクト通知先メール |
| `AWS_SES_*` | 本番メール送信用 AWS SES 設定 |
