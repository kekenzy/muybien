# ドキュメント索引

リポジトリ内の Markdown を目的別に整理した入口です。新規参加者は **README → 本番なら PRODUCTION / DEPLOYMENT** の順が読みやすいです。

---

## すぐ読む順（おすすめ）

| 順 | ドキュメント | 誰向け | 内容 |
|----|----------------|--------|------|
| 1 | [README.md](README.md) | 全員 | 概要・ローカル Docker セットアップ |
| 2 | [PRODUCTION.md](PRODUCTION.md) | 運用・本番 | **本番の環境変数・SES・migrate 等** |
| 3 | [DEPLOYMENT.md](DEPLOYMENT.md) | 本番デプロイ | Lightsail インスタンス作成・初期設定・デプロイ |
| 4 | [SSL_SETUP.md](SSL_SETUP.md) | 本番 | HTTPS（Let's Encrypt） |
| 5 | [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) | 本番 | Lightsail ファイアウォール・ポート |

---

## 全ドキュメント一覧

| ファイル | 概要 |
|----------|------|
| [README.md](README.md) | プロジェクト説明、ローカル開発、システム構成 |
| [DOCUMENTATION.md](DOCUMENTATION.md) | 本ファイル（索引） |
| [PRODUCTION.md](PRODUCTION.md) | **本番環境の設定**（環境変数、SES、付帯作業） |
| [DEPLOYMENT.md](DEPLOYMENT.md) | AWS Lightsail デプロイ、SSH 設定、初回セットアップ |
| [SSL_SETUP.md](SSL_SETUP.md) | Let's Encrypt 前提条件と証明書取得手順 |
| [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md) | Lightsail のファイアウォール・ポート・DNS |
| [CLAUDE.md](CLAUDE.md) | AI 開発者向けの簡易リファレンス |

---

## テーマ別

### 本番サーバ・公開

- 全体の流れ: [DEPLOYMENT.md](DEPLOYMENT.md)
- **環境変数・SES・migrate**: [PRODUCTION.md](PRODUCTION.md)
- HTTPS: [SSL_SETUP.md](SSL_SETUP.md)
- ネットワーク: [LIGHTSAIL_NETWORK_SETUP.md](LIGHTSAIL_NETWORK_SETUP.md)

### 開発

- 初期セットアップ: [README.md](README.md)
- 開発コマンド: [CLAUDE.md](CLAUDE.md)
- 永井のLab（管理者ログイン）: [README.md](README.md)「永井のLab」、本番のユーザー作成は [PRODUCTION.md](PRODUCTION.md)

---

## デプロイスクリプト

| スクリプト | 実行場所 | 用途 |
|-----------|---------|------|
| `scripts/deploy.sh` | ローカル | フロントビルド + rsync + 本番起動 |
| `scripts/deploy_lightsail.sh` | サーバー | docker compose up |
| `scripts/setup_lightsail.sh` | サーバー | 初回セットアップ（Docker 等） |
| `scripts/prod-logs.sh` | ローカル | 本番ログ表示 |
| `scripts/prod-migrate.sh` | ローカル | 本番マイグレーション |
| `scripts/prod-createsuperuser.sh` | ローカル | 本番スーパーユーザー作成（Lab / Admin） |
| `scripts/prod-bash.sh` | ローカル | 本番 API コンテナシェル |
| `scripts/prod-down.sh` | ローカル | 本番コンテナ停止 |

---

## メンテナンスメモ

- 新しい `.md` をルートに追加したら、**本ファイルの「全ドキュメント一覧」に 1 行追加**する。
- 本番の秘密情報は **Markdown に実値を書かない**（プレースホルダまたは変数名のみ）。
