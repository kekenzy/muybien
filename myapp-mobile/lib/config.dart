// API のベースURL。実機/エミュレータの環境に合わせて変更するか、
// `flutter run --dart-define=API_BASE_URL=https://example.com/v1/api` で上書きする。
//
// - iOS シミュレータ / 実マシンの Web と同じネットワーク: http://<PCのLAN IP>:8000/v1/api
// - Android エミュレータ: http://10.0.2.2:8000/v1/api
// - 本番: https://<公開ドメイン>/v1/api
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  // 実機のホーム画面起動用（make ios-install）は本番URLを dart-define で渡す。
  // Android エミュレータのデフォルト:
  defaultValue: 'http://10.0.2.2:8000/v1/api',
);
