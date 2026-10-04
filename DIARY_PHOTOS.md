# 日記の写真（Web・スマホ・S3）

Lab の日記に写真を添付する機能の手順です。索引は [DOCUMENTATION.md](DOCUMENTATION.md)。本番の環境変数の置き場は [PRODUCTION.md](PRODUCTION.md)。

写真はアップロード時に JPEG（長辺 1600px、品質 72）へ変換して保存します。iPhone の HEIC も受け付けます。1 枚の上限は 20MB です。日記のオブジェクトキーは `diary/<日記ID>/<uuid>.jpg`、メモのオブジェクトキーは `memo/<メモID>/<uuid>.jpg` です。どちらも同じバケットと変換処理を使います。

---

## いまの保存先

`AWS_S3_DIARY_BUCKET` が空のあいだ、写真は本番サーバーのメディア領域（nginx の `/media/`）に保存されます。バケット名を設定したあとの新規写真から S3 に入ります。それ以前のファイルはサーバー上に残ります。

S3 利用時の URL は 7 日間の署名付き URL です。バケットは非公開のままにします。

通常の S3 バケット `muybien-diary-photo` を使います。本番サーバーは Lightsail のロール `AmazonLightsailInstanceRole`（アカウント `641965853838`）として S3 を呼びます。このロールは IAM からも、バケットポリシーからも、通常の S3 への書き込みを足せません。サーバーからの `PutObject` は `AccessDenied` のままです。

書く権限は、そのバケットの `diary/*` と `memo/*` だけを許可した IAM ユーザーのアクセスキーで渡します。ブロックパブリックアクセスはオンのままにします。`Principal` が `*` の公開ポリシーは使いません。`diary/*` だけのポリシーではメモ写真の保存が `AccessDenied` になります。

---

## AWS（S3 バケット）の手順

バケット名は `muybien-diary-photo`、リージョンは東京（`ap-northeast-1`）です。S3 を開いているのと同じアカウントで行います。

### 1. 書き込み専用の IAM ユーザーを作る

1. IAM の **ユーザー** からユーザーを作る。コンソールへのログイン権限は付けない
2. **アクセスキー** を発行する（表示は一度だけ）
3. そのユーザーに、次のインラインポリシーだけを付ける

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": [
        "arn:aws:s3:::muybien-diary-photo/diary/*",
        "arn:aws:s3:::muybien-diary-photo/memo/*"
      ]
    }
  ]
}
```

バケットポリシーに `AmazonLightsailInstanceRole` を書いても、このインスタンスからの `PutObject` は `AccessDenied` のままです。ロール ARN は合っています。

### 2. 本番の環境変数を設定する

サーバーの `/home/ec2-user/muybien/.env.prod` に追加します。このファイルは git に含めません。

```env
AWS_ACCESS_KEY_ID=発行したアクセスキーID
AWS_SECRET_ACCESS_KEY=発行したシークレット
AWS_S3_DIARY_BUCKET=muybien-diary-photo
AWS_S3_REGION=ap-northeast-1
```

`restart` では環境変数が更新されないため、API コンテナを作り直します。

```bash
ssh muy 'cd /home/ec2-user/muybien && sudo docker compose -f docker-compose.prod.yml up -d myapp-api'
```

環境変数にキーがあると、アプリはそのキーで S3 に書きます。

### 3. 画面で確認する

Lab の日記で写真を 1 枚保存し、S3 の `diary/` 配下にオブジェクトが増えることを確認します。画面に出る URL は `https://muybien.jp/media/...` ではなく、S3 の署名付き URL になります。

---

## アプリ側の手順

### Web（Lab）

本番の日記画面はデプロイ済みです。

1. https://muybien.jp/lab/login でログインする
2. 日記を開き、日付を選ぶ
3. 「カメラ」または「ファイルを選択」で画像を付ける
4. 「保存する」または「更新する」を押す

付いた写真をタップすると削除予定になり、保存したときに消えます。「追加分を取り消す」は、まだ保存していないファイルだけを外します。本文が空でも、写真があれば保存できます。

### スマホ（Muybien Memo）

日記として保存したメモだけ写真を付けられます（「メモ」種別には写真欄がありません）。Release ビルドは本番 API（`https://muybien.jp/v1/api`）に接続します。

1. iPhone を USB で接続し、ロックを解除する
2. リポジトリ直下で次を実行する

```bash
make ios-install
```

3. 初回、または再インストール後に起動できないときは、端末の「設定 → 一般 → VPNとデバイス管理」で開発元を信頼してからアイコンをタップする
4. アプリでログインし、日記を開く
5. 「カメラ」または「ファイル」を押し、保存する

カメラとフォトライブラリの利用目的は `Info.plist` に記載済みです。ローカル API に繋ぐ場合は次のようにします。

```bash
API_BASE_URL=http://192.168.x.x:8000/v1/api make ios-install
```

詳細は [myapp-mobile/README.md](myapp-mobile/README.md)。
