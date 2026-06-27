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
- 認証なし（AllowAny）
- アプリは `contact/` のみ
- 設定: `core/settings/common.py` + `core/settings/environments/{local,production}.py`
- メール: ローカルはコンソール出力 / 本番は AWS SES
- ログ: `log/app.log`

**Frontend (`myapp-web/app/src/`)**
- Vue 3 + TypeScript + Vite 5
- **Tailwind CSS 4** — `@tailwindcss/vite` プラグイン、`src/assets/main.css` で `@import "tailwindcss"`
- テーマカラー等は `main.css` の `@theme { }` で定義（`--color-primary` 等）
- 条件付きクラス結合は `src/lib/utils.ts` の `cn()` を使う
- UI: `radix-vue` + `lucide-vue-next`（Tailwind で見た目を当てる）
- ルーター: `/`, `/services`, `/portfolio`, `/profile`, `/contact`
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

※ DRF Router は使わず直接 `path()` 登録。trailing_slash なし。

---

## Common Development Commands (run from `MuyBienBase/`)

```bash
make up              # コンテナ起動
make down            # コンテナ停止
make restart         # コンテナ再起動
make logs            # 全コンテナログ
make api-logs        # API ログ
make api-bash        # API コンテナ内シェル
make web-bash        # フロントコンテナ内シェル
make migrate         # マイグレーション適用
make makemigrations  # マイグレーションファイル生成
make createsuperuser # スーパーユーザー作成
make build-front     # フロントのプロダクションビルド
```

**Access**:
- フロント: `http://localhost:5173`
- API: `http://localhost:8000/v1/api/contact`
- Django Admin: `http://localhost:8000/admin/`

---

## Production Deployment

- サーバー: AWS EC2 (SSH alias: `muy`, ユーザー: `ec2-user`)
- デプロイ先: `/home/ec2-user/muybien`
- **詳細ドキュメント**: [DOCUMENTATION.md](DOCUMENTATION.md) → [DEPLOYMENT.md](DEPLOYMENT.md)

```bash
make prod-deploy     # ビルド + rsync + docker-compose up（本番）
make prod-logs       # 本番ログ
make prod-migrate    # 本番マイグレーション
make prod-bash       # 本番APIコンテナシェル
make prod-down       # 本番停止
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
