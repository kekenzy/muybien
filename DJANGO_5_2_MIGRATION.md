# Django 4.2 → 5.2 LTS 移行メモ（MuyBien API）

2026-11-11。Django 4.2 系は 2026年4月でサポートが終わったため、`myapp-api/django/` を 5.2 LTS（サポートは 2028年4月まで）に上げた。
共通の手順は morinaga_clinic の `docs/DJANGO_5_2_MIGRATION.md` にある。ここには MuyBien で実際にやったことだけを書く。

## 前提の確認

| 項目 | 状態 |
|---|---|
| Python | `Dockerfile`・`Dockerfile_prd` とも `python:3.11-slim`（5.2・Pillow 13 の条件を満たす。変更なし） |
| PostgreSQL | ローカル・本番とも `postgres:16.2`（5.2 は 14 以上。変更なし） |

## 依存（`myapp-api/django/requirements.txt`）

| ライブラリ | 旧 | 新 | メモ |
|---|---|---|---|
| Django | 4.2.13 | 5.2.19 | 5.2 の最新パッチ |
| djangorestframework | 3.15.2 | 3.18.3 | 3.17 から Django 5.2 以上が必須 |
| djangorestframework-simplejwt | 5.3.1 | 5.5.1 | ログイン・更新・失効の応答は変わらない（テストで確認） |
| django-cors-headers | 4.4.0 | 4.9.0 | |
| psycopg2-binary | 2.9.9 | 2.9.13 | |
| gunicorn | 22.0.0 | 27.0.0 | `gunicorn --check-config` で本番と同じ引数が通る |
| Pillow | 10.4.0 | 13.0.0 | Python 3.11 以上 |
| pillow-heif | 0.18.0 | 1.8.1 | Pillow 11.1 以上が必要なので一緒に上げた。`register_heif_opener()` はそのまま |
| stripe | 15.3.0 | 15.6.2 | メジャー（16）は API が変わるので 15 系の最新にとどめた |
| boto3 | 1.35.36 | 1.44.0 | |

`pip-audit -r requirements.txt` で「No known vulnerabilities found」、`pip check` も問題なし。

## コードの変更

- 4.2 → 5.2 で消えた・非推奨になったもの（`STATICFILES_STORAGE`・`DEFAULT_FILE_STORAGE`・`USE_L10N`・`pytz`・`index_together`・`LogoutView`・`format_html` の引数なし・`URLField` など）は使っていなかった。API だけでテンプレートのログアウトも無い（Lab のログアウトは JWT の `auth/logout`＝`TokenBlacklistView`）
- `makemigrations --check` は「No changes detected」。マイグレーションの追加は無い
- `lab/tests.py` に、移行で振る舞いが変わっていないことを見るテストを足した
  - JWT: ログイン → `auth/me`、パスワード違いは 401、refresh のローテーションで古い refresh は 401、`auth/logout` 後の refresh は 401、不正なアクセストークンは 401
  - コンタクトフォーム: 201 で保存・メール2通、メールアドレスが不正なら 400
- `scripts/deploy.sh`: `BUILD=1 make deploy` の `BUILD` がサーバー側の `deploy_lightsail.sh` に渡っておらず、イメージが作り直されなかった。渡すように直した（requirements を変えたので今回のデプロイで必要）

## 確かめたこと（Docker）

ワークツリーで `docker-compose -p muy52`（コンテナ名だけ変える上書きファイル付き、空の DB）で起動した。

- `migrate` が空の DB で全件通る。`createcachetable` も通る
- `python -W error::DeprecationWarning -W error::PendingDeprecationWarning manage.py test` で 37 件すべて通る。`-W always` でも警告は 0 件
- `manage.py check`（警告をエラー扱い）で問題なし
- API を curl で（直接 :8000 と Vite のプロキシ :5173 の両方）: ログイン、`auth/me`、refresh のローテーションと古い refresh の失効、ログアウト後の refresh 401、トークンなし 401、コンタクト 201 と Mailpit へのメール、メモ・タスク・日記の作成と更新、メモ写真のアップロードと署名付き URL（正しい署名は 200、改ざんは 404）、Lab の各一覧 API
- ブラウザ（Vue）で: Lab ログイン、お問い合わせ一覧・パスワード変更・顧客・タスク・日記・メモ（写真表示）・Daily・予約・ユーザー・権限・お知らせ・サイトコンテンツの各画面、公開サイトのトップ・サービス・実績・プロフィール・コンタクト（送信して受付表示まで）。コンソールエラーなし、API はすべて 2xx

## 確かめていないこと・注意

- 既存データのある DB での `migrate`。今回はマイグレーションの追加が無いので、本番の `migrate` は「適用なし」になるはず
- Flutter アプリ（myapp-mobile）からの実機確認。API の応答形式は変わっていない（上のテストと curl で確認）
- 本番は requirements を変えたので **`BUILD=1 make deploy`** でイメージを作り直す。インスタンスのメモリが小さいので、ビルド中に重くなる可能性がある（今回の依存はすべて wheel があり、コンパイルは走らない想定）
- 元からの不具合（移行とは無関係）: 日記を同じ日付で2回 POST すると、`owner` がシリアライザに無いため DRF の一意チェックが付かず、DB の `unique_together` で 500 になる。Vue の画面は既存の日記を更新するので通常は起きない

## 戻し方

```bash
git revert <この移行のコミット>   # requirements.txt などが 4.2 の版に戻る
BUILD=1 make deploy               # 本番のイメージを 4.2 の版で作り直す
```

マイグレーションの追加が無いので、DB を戻す作業は要らない。
