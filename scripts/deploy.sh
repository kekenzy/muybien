#!/bin/bash
# ローカルから AWS Lightsail へデプロイするスクリプト
# 使い方:
#   ./scripts/deploy.sh                       本番(AWS Lightsail)へデプロイ  または  make prod-deploy
#   ./scripts/deploy.sh --ios --run           Muybien Memo を接続中のiOS実機にビルド・インストール  または  make ios-install
#   ./scripts/deploy.sh --android --run       Muybien Memo を接続中のAndroid実機にビルド・インストール  または  make android-install
#   ./scripts/deploy.sh --ios --run <device_id>   デバイスを明示指定（複数台接続時など）
#   ./scripts/deploy.sh --ios-release         App Store 提出用 IPA をビルド  または  make ios-release
#     （myapp-mobile/ios/exportOptions.plist が無ければ Xcode プロジェクトの
#       DEVELOPMENT_TEAM から自動生成される。別チームの場合は
#       myapp-mobile/ios/exportOptions.plist.sample をコピーして teamID を書き換えること）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

if [[ "$1" == "--ios" || "$1" == "--android" ]]; then
    PLATFORM="${1#--}"
    if [[ "$2" != "--run" ]]; then
        echo "❌ 使い方: ./scripts/deploy.sh --ios --run [device_id]"
        echo "         ./scripts/deploy.sh --android --run [device_id]"
        exit 1
    fi
    DEVICE_ID="$3"

    FLUTTER_SDK_BIN="/Volumes/DevDisk/01_dev/12_flutter/99_sdk/flutter/bin"
    if ! command -v flutter >/dev/null 2>&1; then
        export PATH="$FLUTTER_SDK_BIN:$PATH"
    fi

    cd "$PROJECT_ROOT/myapp-mobile"

    if [ -z "$DEVICE_ID" ]; then
        echo "🔍 接続中の${PLATFORM}デバイスを検索中..."
        PLATFORM_PATTERN="ios"
        [[ "$PLATFORM" == "android" ]] && PLATFORM_PATTERN="^android"
        DEVICE_ID="$(flutter devices 2>/dev/null | awk -F' • ' -v p="$PLATFORM_PATTERN" 'NF >= 3 && tolower($3) ~ p { print $2; exit }')"
        if [ -z "$DEVICE_ID" ]; then
            echo "❌ ${PLATFORM}デバイスが見つかりません。接続・信頼設定を確認してください。"
            flutter devices
            exit 1
        fi
        echo "✅ デバイス検出: ${DEVICE_ID}"
    fi

    echo "📱 Muybien Memo(${PLATFORM}) を ${DEVICE_ID} にビルド・インストール中..."
    flutter pub get

    # ホーム画面から起動するには Debug 不可（JIT）。Release で入れる。
    # API は本番をデフォルト（ローカルAPIは端末から届かないことが多い）
    API_BASE_URL="${API_BASE_URL:-https://muybien.jp/v1/api}"
    echo "🔗 API_BASE_URL=${API_BASE_URL}"

    if [[ "$PLATFORM" == "ios" ]]; then
        flutter build ios --release --dart-define=API_BASE_URL="${API_BASE_URL}"
        flutter install --release -d "$DEVICE_ID"
        BUNDLE_ID="com.muybien.muybienMemo"
        echo "🚀 端末で起動を試みます (${BUNDLE_ID})..."
        if ! xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null; then
            echo "⚠️  自動起動に失敗しました。端末上で「Muybien Memo」をタップして起動してください。"
            echo "   （初回は「信頼されていないデベロッパ」の場合、設定 > 一般 > VPNとデバイス管理 で信頼）"
        fi
    else
        flutter build apk --release --dart-define=API_BASE_URL="${API_BASE_URL}"
        flutter install --release -d "$DEVICE_ID"
    fi

    echo ""
    echo "✅ インストール完了（Release）。ホーム画面から起動できます。"
    echo "   ローカルAPIに繋ぐ場合: API_BASE_URL=http://<MacのLAN IP>:8000/v1/api make ios-install"
    exit 0
fi

if [[ "$1" == "--ios-release" ]]; then
    FLUTTER_SDK_BIN="/Volumes/DevDisk/01_dev/12_flutter/99_sdk/flutter/bin"
    if ! command -v flutter >/dev/null 2>&1; then
        export PATH="$FLUTTER_SDK_BIN:$PATH"
    fi

    cd "$PROJECT_ROOT/myapp-mobile"

    # 本番APIをデフォルトにする（App Store 提出物はローカルAPIに繋がないため）
    API_BASE_URL="${API_BASE_URL:-https://muybien.jp/v1/api}"
    echo "📦 Muybien Memo(iOS) のリリース用 IPA をビルド中..."
    echo "🔗 API_BASE_URL=${API_BASE_URL}"

    flutter pub get

    EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-ios/exportOptions.plist}"
    if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
        # 未作成なら Xcode プロジェクトの DEVELOPMENT_TEAM から自動生成する
        TEAM_ID="$(grep -m1 'DEVELOPMENT_TEAM = ' ios/Runner.xcodeproj/project.pbxproj | sed -E 's/.*DEVELOPMENT_TEAM = ([A-Z0-9]+);/\1/')"
        if [ -z "$TEAM_ID" ]; then
            echo "❌ ${EXPORT_OPTIONS_PLIST} が見つからず、Team ID も自動検出できませんでした。"
            echo "   cp ios/exportOptions.plist.sample ios/exportOptions.plist"
            echo "   を実行し、teamID を Apple Developer Team ID に書き換えてください。"
            exit 1
        fi
        echo "📝 ${EXPORT_OPTIONS_PLIST} が無いため、Xcode プロジェクトの Team ID (${TEAM_ID}) から自動生成します..."
        sed "s/YOUR_TEAM_ID/${TEAM_ID}/" ios/exportOptions.plist.sample > "$EXPORT_OPTIONS_PLIST"
    fi
    echo "📝 エクスポートオプション: ${EXPORT_OPTIONS_PLIST}"

    flutter build ipa --release \
        --dart-define=API_BASE_URL="${API_BASE_URL}" \
        --export-options-plist="${EXPORT_OPTIONS_PLIST}"

    IPA_PATH="$(find "$PROJECT_ROOT/myapp-mobile/build/ios/ipa" -maxdepth 1 -name '*.ipa' 2>/dev/null | head -n 1)"
    echo ""
    if [ -n "$IPA_PATH" ]; then
        echo "✅ IPA ビルド完了"
        echo "📦 出力先: ${IPA_PATH}"
        echo "   Transporter アプリ、または"
        echo "   xcrun altool --upload-app -f \"${IPA_PATH}\" -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>"
        echo "   で App Store Connect にアップロードできます。"
    else
        echo "❌ IPA の生成に失敗しました（アーカイブの署名・エクスポートでエラー）。"
        echo "   Apple Developer Program（有料、年間\$99）への登録と、"
        echo "   iOS Distribution 証明書・App Store 用プロビジョニングプロファイルの作成が必要です。"
        echo "   アーカイブ自体は成功しているので、Xcode から手動エクスポートもできます:"
        echo "     open $PROJECT_ROOT/myapp-mobile/build/ios/archive/Runner.xcarchive"
        exit 1
    fi
    exit 0
fi

echo "🚀 Lightsail へのデプロイを開始します..."
echo "📍 ターゲット: ${SSH_USER}@${SSH_HOST}:${PROD_DIR}"

# SSH 接続テスト
echo "🔌 SSH 接続をテスト中..."
if ! ssh -o ConnectTimeout=10 "${SSH_HOST}" "echo 'SSH接続成功'" 2>/dev/null; then
    echo "❌ SSH 接続に失敗しました。~/.ssh/config を確認してください。"
    echo ""
    echo "   例:"
    echo "   Host muy"
    echo "     HostName YOUR_SERVER_IP"
    echo "     User ec2-user"
    echo "     IdentityFile ~/.ssh/your-key.pem"
    exit 1
fi
echo "✅ SSH 接続成功"

# フロントエンドビルド
echo "📦 フロントエンドをビルド中..."
cd "$PROJECT_ROOT/myapp-web/app"
if [ ! -f node_modules/.bin/vite ]; then
    echo "📥 npm install を実行中..."
    npm install
fi
npm run build
# macOS 等で dist が 0700 になると nginx ワーカーが読めず 403 になる
chmod -R a+rX dist
cd "$PROJECT_ROOT"

# サーバーにディレクトリ作成
echo "📁 デプロイ先ディレクトリを確認中..."
ssh "${SSH_HOST}" "mkdir -p ${PROD_DIR}"

# ファイル転送
echo "📤 ファイルを転送中..."
rsync -avz --delete \
    "${RSYNC_EXCLUDES[@]}" \
    "$PROJECT_ROOT/" "${SSH_HOST}:${PROD_DIR}/"

# 転送後も念のため dist を nginx から読める権限にする
ssh "${SSH_HOST}" "chmod -R a+rX ${PROD_DIR}/myapp-web/app/dist"

# リモートでデプロイスクリプト実行
echo "🔄 本番コンテナを起動中..."
ssh "${SSH_HOST}" "PROD_DIR=${PROD_DIR} PROD_DOMAIN=${PROD_DOMAIN} COMPOSE_FILE=${COMPOSE_FILE} bash ${PROD_DIR}/scripts/deploy_lightsail.sh"

echo ""
echo "✅ デプロイが正常に完了しました！"
echo "🌐 本番確認: ssh ${SSH_HOST} 'cd ${PROD_DIR} && docker compose -f ${COMPOSE_FILE} ps'"
