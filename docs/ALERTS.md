# 異常・攻撃の通知（アラートメール）

DoS（大量アクセス）・不正侵入の試み・アプリの異常・サイトの停止を検知したら、
**kekenzy＠gmail.com** へメールで知らせる。届いたメールは司令塔（`_hub`）の定期タスクが Gmail で読み、まとめて報告する。

## 件名の決まり（全プロジェクト共通。変えないこと）

```
[ALERT][MuyBienBase][<種類>] <要約>
```

| 種類 | 意味 | 送るもの |
|------|------|----------|
| `dos` | 大量アクセス・回数制限の多発 | Django の回数制限の多発 / fail2ban が nginx の回数制限で遮断 |
| `intrusion` | 不正なログインの試み・遮断の記録 | Lab ログインのアカウントロック / fail2ban が SSH・ログイン API の失敗で遮断 |
| `error` | アプリの異常 | Django の 500 エラー |
| `down` | サービスが止まった | 5分ごとの死活確認が2回続けて失敗（復旧したらもう1通） |

本文には「日時・サーバー名・サイト・何が・URL・回数・アクセス元 IP・自動でしたこと」を書く。
パスワード・トークン・リクエストの中身（お問い合わせの内容など）は書かない。ユーザー名は先頭2文字だけ。

**送りすぎ防止**: 同じ種類は **15分に1通まで**（`ALERT_COOLDOWN_SECONDS`）。間に起きたものは溜めておき、
次の通知か、5分ごとのタイマー（`tick`）で「まとめ: N 件」として送る。1時間に同じ種類は最大4通。

## 全体の形

```
               ┌──────────── Lightsail（Amazon Linux 2023） ────────────┐
インターネット → │ iptables（fail2ban が遮断）                             │
               │   ↓                                                      │
               │ nginx コンテナ  limit_req で回数制限 → 429               │
               │   │  ログ: /var/log/muybien-nginx/{access,error}.log ─┐   │
               │   ↓                                                 │   │
               │ Django コンテナ  ScopedRateThrottle・ログインロック・500 │   │
               │   └→ core/alerts.py → SES ──────────────┐            │   │
               │                                         │            │   │
               │ fail2ban コンテナ ← /var/log/secure（SSH）, nginx ログ ┘   │
               │   └→ deploy/alert/muybien_alert.py → SES ┤                 │
               │ systemd タイマー（5分）→ 死活確認・まとめ送信 ┘              │
               └──────────────────────────────────────────────────────────┘
                                                        ↓
                                              kekenzy＠gmail.com → 司令塔の定期タスク
```

送信はどれも `.env.prod` の `EMAIL_*`（AWS SES の SMTP）を使う。サーバーに別のメールの仕組みは入れない。

## しきい値と、正しいアクセスを止めないための除外

| 仕組み | しきい値 | 自動でしたこと | 正しいアクセスへの配慮 |
|--------|----------|----------------|------------------------|
| Django 回数制限（既存） | login 10/分・contact 5/時・password_reset 5/時・password_change 10/時（IP ごと） | 429 | 変更なし |
| Django 回数制限の通知 | 同じスコープで止めた件数が **10分に20件** | 通知のみ | 1人の打ち間違いでは届かない件数。`ALERT_THROTTLE_THRESHOLD` で変更可 |
| Lab ログインロック（既存）の通知 | 同じユーザー名で **10回失敗**（15分ロック） | 通知のみ | — |
| nginx `api` | `/v1/api/` 全体で **毎秒20・まとめて100まで**（IP ごと） | 429 | 写真一覧などで一度に多く読んでも届かない幅 |
| nginx `auth` | `auth/login`・`auth/password-reset(/confirm)`・`auth/change-password`・`lab/set-password`・`contact` に **毎分30・まとめて10まで** | 429 | **`auth/refresh`・`auth/me` は対象外**（画面やスマホアプリ Muybien Memo が普段から呼ぶため）。Django 側の制限より緩い |
| fail2ban `sshd` | SSH ログイン失敗 **10分に5回** | その IP を1時間遮断（INPUT） | 自分の IP を `ignoreip` に足せる |
| fail2ban `nginx-limit-req` | nginx の回数制限に **10分に10回** 当たる | 1時間遮断（DOCKER-USER） | 普段の利用では回数制限自体に当たらない |
| fail2ban `muybien-auth` | ログイン系 API の失敗（400/401/429）が **10分に20回** | 1時間遮断（DOCKER-USER） | `auth/refresh`・`auth/me` の 401（トークン切れ）は数えない |

- fail2ban の遮断は、繰り返すたびに倍々に延びる（最長1週間）。
- `ignoreip` は `127.0.0.1/8 ::1 172.16.0.0/12`（自分自身と Docker 内部）。自宅・事務所の固定 IP があれば
  `deploy/fail2ban/jail.d/muybien.local` に足す。携帯回線は IP が変わるので足さない。
- 誤って遮断したときの解除: `sudo docker exec muybien-fail2ban fail2ban-client set <jail名> unbanip <IP>`
  （通知メールの本文にもそのままのコマンドを書いている）。

## ファイル

| ファイル | 内容 |
|----------|------|
| `myapp-api/django/core/alerts.py` | 件名・間隔・まとめ送信。500 エラー用のハンドラ（`AdminEmailHandler` を継承） |
| `myapp-api/django/core/throttling.py` | `AlertingScopedRateThrottle`（止めた件数を数えて `dos` を送る） |
| `myapp-api/django/core/management/commands/alert.py` | `manage.py alert test` / `manage.py alert flush` |
| `nginx/conf.d/production.conf` | `limit_req` と、fail2ban 用のログファイル出力 |
| `deploy/fail2ban/` | fail2ban（Docker）の jail・filter・action と `docker-compose.yml` |
| `deploy/alert/muybien_alert.py` | サーバー側の通知スクリプト（標準ライブラリのみ） |
| `deploy/systemd/muybien-alert-tick.{service,timer}` | 5分ごとの死活確認とまとめ送信 |
| `deploy/logrotate/muybien-nginx` | nginx ログのローテーション |

Django の設定（`core/settings/common.py`）: `ADMINS`（= `ALERT_EMAIL`）・`SERVER_EMAIL`（= `DEFAULT_FROM_EMAIL`。SES で送れる差出人）・
`EMAIL_SUBJECT_PREFIX=''`。500 エラーは `django.request` の ERROR だけを送る（4xx は送らない）。

## 本番への入れ方（ユーザーの承認を取ってから）

前提: このブランチが main にマージされ、`make deploy` 済み（nginx の回数制限・Django の通知はデプロイだけで有効になる）。
以下はサーバー上（`ssh muy`）で1回だけ行う。

### 1. `.env.prod` に追記

```bash
cd /home/ec2-user/muybien
echo 'ALERT_SERVER_NAME=muybien-lightsail' >> .env.prod
```

`ALERT_EMAIL` は未設定なら `kekenzy@gmail.com`。`DEFAULT_FROM_EMAIL` は SES で認証済みの差出人であること。
追記したら `sudo docker compose -f docker-compose.prod.yml up -d myapp-api` で API を作り直す（env_file は再作成で読み直す）。

### 2. SSH のログをファイルに出す（rsyslog）

Amazon Linux 2023 は標準では journald だけで `/var/log/secure` が無い。fail2ban（コンテナ）が読めるよう rsyslog を入れる。

```bash
sudo dnf install -y rsyslog
sudo systemctl enable --now rsyslog
ls -l /var/log/secure
```

### 3. nginx ログのローテーション

```bash
sudo cp deploy/logrotate/muybien-nginx /etc/logrotate.d/muybien-nginx
sudo logrotate -d /etc/logrotate.d/muybien-nginx   # 試し実行（何もしない）
```

### 4. fail2ban を起動

```bash
sudo mkdir -p /var/lib/muybien-fail2ban /var/lib/muybien-alert
cd /home/ec2-user/muybien/deploy/fail2ban
sudo docker compose up -d
sudo docker exec muybien-fail2ban fail2ban-client status          # sshd・nginx-limit-req・muybien-auth の3つ
```

遮断が効くかの確認（文書用の IP 192.0.2.1 を使う。通知が1通届く）:

```bash
sudo docker exec muybien-fail2ban fail2ban-client set muybien-auth banip 192.0.2.1
sudo iptables -S DOCKER-USER | grep f2b      # -j f2b-muybien-auth が出る
sudo iptables -S f2b-muybien-auth            # 192.0.2.1 の REJECT が出る
sudo docker exec muybien-fail2ban fail2ban-client set muybien-auth unbanip 192.0.2.1
```

- nginx は Docker で動くので、ホストの INPUT ではなく **DOCKER-USER** チェーンで止めている（INPUT に入れても Docker の転送が先に通ってしまう）。
- Docker を再起動したあとは、念のため `sudo docker restart muybien-fail2ban` で遮断のルールを入れ直す。
- iptables の方式（nft / legacy）は自動判定（`IPTABLES_MODE=auto`）。Amazon Linux 2023 の Docker は nft。

### 5. 5分ごとのタイマー（死活確認・まとめ送信）

```bash
sudo cp deploy/systemd/muybien-alert-tick.service deploy/systemd/muybien-alert-tick.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now muybien-alert-tick.timer
sudo systemctl start muybien-alert-tick.service && sudo journalctl -u muybien-alert-tick.service -n 20
```

死活確認の URL は `FRONTEND_BASE_URL` + `/v1/api/site-content`（`ALERT_HEALTH_URL` で変更可）。
サーバー自身から確かめるので、サーバーごと止まったときは届かない（そのときは司令塔側で「通知も来ない」ことに気づく必要がある）。

### 6. テスト通知

ローカル PC から（kekenzy＠gmail.com へ実際に2通届く）:

```bash
make prod-alert-test
```

- `[ALERT][MuyBienBase][error] テスト通知です（対応は不要です）` … Django 側
- `[ALERT][MuyBienBase][intrusion] テスト通知です（対応は不要です・サーバー側）` … fail2ban・死活確認側

ローカルで Django 側だけ試すときは `make alert-test`（Mailpit http://localhost:8025 に届く）。
サーバー側スクリプトは `--dry-run` で送らずに中身を表示できる。

## 確かめたこと（ローカル）

- Django のテスト（`core/tests.py`）: 件名の形・15分の間隔とまとめ・500 の本文にトークンやリクエストの中身が入らないこと・
  回数制限の件数でのしきい値・ログインロックの通知。
- `nginx -t` で設定の文法。
- fail2ban 1.1.0（`crazymax/fail2ban:1.1.0`）の `fail2ban-regex` で、攻撃の行だけが当たり `auth/refresh`・`auth/me` の 401 は当たらないこと。
  実際にコンテナで jail を動かし、遮断 → 通知メール（Mailpit）までを確認。
