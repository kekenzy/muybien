# myapp-mobile（メモアプリ / Flutter）

永井のLabの「メモ」機能（`/v1/api/lab/memos`）を iOS/Android から使うための Flutter アプリ。
Vue の Lab と同じ JWT 認証（`/v1/api/auth/login` / `/auth/refresh`）でログインし、メモの一覧・追加・編集・削除ができる。

## セットアップ

Flutter SDK は `/Volumes/DevDisk/01_dev/12_flutter/99_sdk/flutter` にある（このリポジトリとは別管理）。PATHに無い場合は以下のように実行する。

```bash
export PATH="/Volumes/DevDisk/01_dev/12_flutter/99_sdk/flutter/bin:$PATH"
cd myapp-mobile
flutter pub get
flutter run   # 接続中のシミュレータ/実機/エミュレータで起動
```

`ios/` `android/` のプラットフォームコードは生成済み。`lib/config.dart` の `apiBaseUrl` を実機/エミュレータの接続先に合わせて調整すること（Android エミュレータはデフォルトの `10.0.2.2` でOK、実機は開発PCのLAN IPに変更）。

## 実機インストール（`make ios-install`）

Debug ビルドはホーム画面から起動できない（即終了する）ため、Release で入れます。API はデフォルトで本番 `https://muybien.jp/v1/api` です。

```bash
make ios-install
# ローカルAPIを使う場合
API_BASE_URL=http://192.168.x.x:8000/v1/api make ios-install
```

初回は「設定 > 一般 > VPNとデバイス管理」で開発元を信頼すること。

## 注意点

- **Android の HTTP通信**: ローカル開発でAPIをhttp（TLSなし）で叩くため、`android/app/src/debug/AndroidManifest.xml` に `android:usesCleartextTraffic="true"` を設定済み（debugビルドのみ有効、本番releaseには影響しない）。
- **権限（RBAC）**: メモAPIは Lab の権限管理（メニュー: `メモ`）に紐づく。ログインするユーザーのロールに「メモ」の参照・編集権限を付与しておくこと（superuser/staffは常にフルアクセス）。
- バックエンドAPIの詳細は `../myapp-api/django/lab/` の `models.py`（`Memo`）, `views.py`（`MemoListCreateView` / `MemoDetailView`）, `urls.py`（`/lab/memos`, `/lab/memos/<id>`）を参照。
