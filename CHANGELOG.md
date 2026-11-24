# CHANGELOG

## 2026-11-24 — プライバシーポリシーの代表者を変更

- `/privacy` の Stella Studio の代表者を「永井 謙史」から「永井 順子」に変更し、最終改定日（2026年11月24日）を表示。窓口メール・住所の扱い（請求があれば開示）は変えていない
- サイト自体は永井 謙史の個人ポートフォリオのため、`index.html` のタイトル・説明、フッターの ©、プロフィール、README・CLAUDE.md の説明は変えていない

## 2026-11-22 — 異常・攻撃をメールで知らせる

- 件名 `[ALERT][MuyBienBase][dos|intrusion|error|down] 要約` で kekenzy@gmail.com へ通知（司令塔の定期タスクが読む）。同じ種類は15分に1通まで、間の分はまとめて送る
- Django: 500 エラー（`ADMINS` + `AdminEmailHandler` を継承。本文にリクエストの中身・変数は載せない）、回数制限で止めた件数が10分に20件、Lab ログインのアカウントロック
- nginx: `limit_req` を追加（API 全体は毎秒20・まとめて100、ログイン系とお問い合わせは毎分30・まとめて10。`auth/refresh`・`auth/me` は対象外）。fail2ban 用にログをホストの `/var/log/muybien-nginx` にも書く
- fail2ban（Docker）と5分ごとの死活確認の設定・手順を追加（本番への導入は未実施）。詳細は [docs/ALERTS.md](docs/ALERTS.md)

## 2026-11-22 — お問い合わせ通知先の既定値を Gmail に変更

- `core/settings/common.py` の `CONTACT_NOTIFY_EMAIL` の既定値（環境変数がないときの送り先）を、勤務先のメールから stellastudio4xx@gmail.com に変更（`env.prod.example` と同じ値）。本番はすでに環境変数で同じ値を設定しているため、動きは変わらない

## 2026-11-19 — フロントの開発用ツールを更新

- vite 5 → 8・@vitejs/plugin-vue 5 → 6・vue-tsc 2 → 3・@tailwindcss/vite 4.3.5（セキュリティレビューの指摘4の残り。開発サーバーのパストラバーサルなど）
- `vite.config.ts` の `__dirname` を `import.meta.dirname` に置き換え（vite 8 の警告）
- Node は 20.19 以上が必要（Docker の `node:20-alpine` は 20.20）。手元で `make up` するときは、古い依存が残った `node_modules` のボリュームを作り直す

## 2026-11-18 — セキュリティレビューの Medium 指摘の対応

- 招待リンク（`lab/set-password`）で、無効にしたユーザーが自分を有効に戻せないようにし、回数制限を付けた
- サイトコンテンツの URL（`url`・`*_url`）に `javascript:` などを登録できないようにし、画面でも危険な URL はリンクにしない
- nginx でセキュリティヘッダー（HSTS・`nosniff`・`X-Frame-Options`・`Referrer-Policy`）を付け、nginx を 1.30 に更新
- `npm audit fix` で axios・vue などを更新
- CSP・PostgreSQL の更新・開発用ツール（vite・vue-tsc）のメジャー更新は未対応（ご本人の判断待ち）。詳細は [docs/SECURITY_REVIEW.md](docs/SECURITY_REVIEW.md)

## 2026-11-18 — OWASP Top 10:2025 / Mobile Top 10 2024 のセキュリティレビュー

- 結果は [docs/SECURITY_REVIEW.md](docs/SECURITY_REVIEW.md)（High 2・Medium 5・Low 12）
- High を修正: ユーザー管理の編集権限だけで `is_staff` を付けたり、上位ユーザー（スタッフ・スーパーユーザー）を編集・削除したりできたのを禁止
- High を修正: お問い合わせ（`POST /v1/api/contact`）に IP ごと 5 回/時の制限を追加（429 を返す）
- テストを 8 件追加

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
