# CHANGELOG

## 2026-11-12〜13 — プライバシーポリシーの追加

- `/privacy` を追加（`PrivacyView.vue`。全10項：事業者・取得する情報・利用目的・第三者提供・委託先と所在国（AWS 東京リージョン／Stripe 米国）・外部送信（Google Fonts）・安全管理措置（個人情報保護法32条）・開示などの請求・窓口・改定）
- お問い合わせフォームにプライバシーポリシーへの同意チェックを追加。API（`/v1/api/contact`）でも `agree_privacy: true` がなければ 400 を返す。`contact/tests.py` にテストを追加
- フッターにお問い合わせ・プライバシーポリシーへのリンクを追加
- 運営者は Stella Studio（代表 永井 謙史）。個人情報の窓口はお問い合わせフォームと stellastudio4xx＠gmail.com（ページ上は全角の＠で表示）
- 本番の `CONTACT_NOTIFY_EMAIL` を勤務先のメールから個人のメール（stellastudio4xx@gmail.com）に変更。変更前の設定はサーバーの `.env.prod.bak-20261113` に保存。`env.prod.example`・PRODUCTION.md・DEPLOYMENT.md の例も更新
- 制定日は 2026-11-13。同日に本番へデプロイ
- 残り：本番からお問い合わせをテスト送信し、通知メールが個人のメールに届くか確認する（SES がサンドボックスなら送信先アドレスの検証が必要）

## 2026-11-11 — API を Django 5.2 LTS へ移行

- Django 4.2.13 → 5.2.19（4.2 は 2026年4月でサポート終了）。あわせて DRF 3.18.3・simplejwt 5.5.1・django-cors-headers 4.9.0・gunicorn 27.0.0・Pillow 13.0.0・pillow-heif 1.8.1・psycopg2-binary 2.9.13・stripe 15.6.2・boto3 1.44.0 に更新（`pip-audit` で既知の脆弱性なし）
- コードの書き換えは不要だった（5.0〜5.2 で消えた機能は未使用、マイグレーションの追加なし）。API の応答は変わらない
- `lab/tests.py` に JWT（ログイン・ローテーション・失効）とコンタクトフォームのテストを追加
- `scripts/deploy.sh`: `BUILD=1 make deploy` の `BUILD` がサーバー側に渡らず、イメージが作り直されなかったのを修正
- 詳細・確認内容・戻し方: [DJANGO_5_2_MIGRATION.md](DJANGO_5_2_MIGRATION.md)

## 2026-07-14/15 — 永井のLab: RBAC・顧客管理・タスク・日記機能の追加

### 概要

「永井のLab」（管理者用SPA）に、ロールベースの権限管理（RBAC）と複数の管理画面を追加。
これまでは `is_superuser`/`is_staff` のみがフルアクセスできる単一画面（お問い合わせ一覧）だったが、
ロール単位でメニューごとの権限（なし/参照/参照・編集）を割り当てられるようになった。

### バックエンド（`myapp-api/django/lab/`）

- **新規モデル**（`models.py`）
  - `Role` — ロール（名前のみ）
  - `RoleMenuPermission` — ロール×メニューの権限レベル（0=なし, 1=参照, 2=参照・編集）
  - `UserProfile` — Django Userに紐づくLabプロフィール（`roles` M2M）
  - `Customer` — 顧客情報（お問い合わせからの引き継ぎ `source_contact`、Labログイン紐付け `user` を保持）
  - `MENU_CHOICES` にメニュー一覧（`contacts`, `customers`, `tasks`, `diary`, `users`, `roles`）を定義
- **マイグレーション** — `0002_role_userprofile_customer_rolemenupermission` を新規作成・適用（本作業でDBに反映済み）
- **権限チェック**（`permissions.py`）
  - `get_menu_level(user, menu_key)` — superuser/staffは常にフル権限、それ以外はユーザーの全ロールのうち最も強い権限レベルを採用
  - `MenuPermission` — DRFの `BasePermission`。ViewSetの `menu_key` 属性を見て、SAFEメソッドは参照権限、それ以外は編集権限を要求
- **招待フロー**（`invitations.py`）— 顧客をLabユーザーとして招待し、パスワード設定リンク付きメールを送信
- **新規API**（`views.py` / `urls.py`）
  - 顧客管理: `GET/POST /lab/customers`, `GET/PUT/DELETE /lab/customers/<id>`, `POST /lab/customers/<id>/invite`
  - タスク管理: `GET/POST /lab/tasks`, `GET/PUT/DELETE /lab/tasks/<id>`
  - 日記: `GET/POST /lab/diaries`, `GET/PUT/DELETE /lab/diaries/<id>`
  - ユーザー管理: `GET/POST /lab/users`, `GET/PUT/DELETE /lab/users/<id>`
  - 権限（ロール）管理: `GET/POST /lab/roles`, `GET/PUT/DELETE /lab/roles/<id>`
  - 初回パスワード設定: `POST /lab/set-password`（未認証・招待メールのリンクから利用）
- **Django Admin**（`admin.py`）— 上記モデルを管理サイトに登録

### フロントエンド（`myapp-web/app/src/`）

- **新規画面**（`views/lab/`）
  - `LabCustomerView.vue` — 顧客管理（Labへの招待ボタン含む）
  - `LabTaskView.vue` — タスク一覧
  - `LabDiaryView.vue` — 日記
  - `LabUserView.vue` — ユーザー管理
  - `LabRoleView.vue` — 権限管理（ロール作成・メニュー権限設定）
  - `LabSetPasswordView.vue` — 招待メールからの初回パスワード設定
- **`lib/permissions.ts`** — `canRead(menuKey)` / `canWrite(menuKey)` によるRBAC判定を追加
- **`router/index.ts`** — 各Labルートに `meta.menuKey` を設定し、`canRead` でアクセス制御。`LAB_MENU_ROUTES` でメニュー⇄パスを対応付け
- **`layouts/LabLayout.vue`** — ナビゲーションを `canRead` でフィルタ表示するよう変更
- **`views/lab/LabDashboardView.vue`** — 大幅拡張（お問い合わせ一覧の表示・権限対応）
- **バージョン** — `package.json` を `0.1.7` → `0.1.15` に更新

### ドキュメント

- `README.md` / `DOCUMENTATION.md` / `PRODUCTION.md` / `DEPLOYMENT.md` / `CLAUDE.md` に、永井のLabのRBACルール（新メニュー追加時に5箇所同時更新が必要な点など）を追記

### 本セッションでの対応

- `lab` アプリのモデル変更（Role/UserProfile/Customer/RoleMenuPermission）に対してマイグレーションファイルが未生成だったため、`makemigrations` で `0002_...` を生成し、ローカルDBに `migrate` を実行して適用。`makemigrations --check --dry-run` で差分なしを確認済み。
