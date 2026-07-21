from django.db import migrations

# 導入前にVueへ直書きされていた内容をそのまま初期データとして投入する。
# 以後はLabの「サイトコンテンツ管理」からこれらの行を編集する。

SITE_TEXTS = {
    'home_hero_badge': 'フリーランス受付中',
    'home_hero_title_line1': 'Build Faster.',
    'home_hero_title_line2': 'Ship Smarter.',
    'home_hero_subtitle': 'AI × Django × AWS で、あなたのプロダクトを最速で動かすエンジニア。',
    'home_stack_heading': '使いこなす技術',
    'home_cta_title': '一緒に、速く\nつくりましょう。',
    'home_cta_subtitle': '初回相談は無料。まずは気軽に話しかけてください。',
    'services_heading': '提供サービス',
    'portfolio_heading': '実績・ポートフォリオ',
    'profile_name': '永井 謙史',
    'profile_tagline': 'AI × Django × AWS で、アイデアを最速でプロダクトに変えるFDE(Forward Deployed Engineer)。ITの力をより身近に。',
    'profile_blog_url': 'https://kenzy-goldentime.blogspot.com/',
    'profile_about_heading': 'こんな人です',
    'profile_career_heading': 'キャリア',
    'profile_apps_heading': '制作アプリ',
    'profile_skills_heading': '技術スタック',
    'profile_cta_title': '一緒に何か\nつくりませんか？',
    'profile_cta_subtitle': '初回相談は無料。気軽にメッセージください。',
}

# (section, [ (order, data_dict), ... ])
CONTENT_ITEMS = {
    'home_stats': [
        {'value': '3×', 'label': '平均開発スピード向上'},
        {'value': '10+', 'label': '納品プロジェクト'},
        {'value': '48h', 'label': '最速納期'},
    ],
    'home_skills': [
        {'icon': 'Bot', 'title': 'Claude / GPT-4', 'desc': 'プロンプト設計・RAG・自動化'},
        {'icon': 'Server', 'title': 'Django REST', 'desc': 'API設計・認証・パフォーマンス'},
        {'icon': 'Layers', 'title': 'Vue3 + Tailwind', 'desc': 'SPA・TypeScript・shadcn-vue'},
        {'icon': 'Cloud', 'title': 'AWS Lightsail', 'desc': 'デプロイ・Nginx・SSL・SES'},
        {'icon': 'Database', 'title': 'PostgreSQL', 'desc': 'スキーマ設計・最適化'},
        {'icon': 'Zap', 'title': 'Cursor IDE', 'desc': 'AI駆動開発で爆速実装'},
    ],
    'services': [
        {
            'category': 'Web開発相談',
            'title': 'Web開発相談',
            'price': 10000,
            'includes': [
                'オンライン30分 × 1回',
                'アーキテクチャレビュー',
                'デプロイ・インフラ相談',
                'コードレビュー対応',
            ],
        },
        {
            'category': 'AI活用',
            'title': 'AIプロンプト設計パッケージ',
            'price': 10000,
            'includes': [
                'ユースケースヒアリング（60分）',
                'プロンプトテンプレート作成',
                'Claude / GPT-4 対応',
                '1週間サポート付き',
            ],
        },
        {
            'category': 'レッスン',
            'title': 'Claude / Cursor 活用レッスン',
            'price': 15000,
            'includes': [
                'オンライン60分 × 1回',
                '開発フロー効率化の実演',
                'カスタム設定のレビュー',
                'アーカイブ動画提供',
            ],
        },
    ],
    'portfolio': [
        {
            'icon': 'Building2',
            'title': '社内業務管理プラットフォーム',
            'period': '2023〜2024',
            'desc': '人事・営業・プロジェクト管理を統合したSaaS型Webアプリ。Claude活用で開発工数を40%削減。',
            'tags': ['Django', 'Vue3', 'AWS', 'PostgreSQL', 'Claude API'],
        },
        {
            'icon': 'CalendarCheck',
            'title': '東西南北（よもひろ）館 — 予約・決済システム',
            'period': '2023',
            'desc': 'Django + Square API 連携による旅館向けオンライン予約管理。クレジット決済・SMS通知・キャンセル自動処理・売上レポートを実装。本番運用中。',
            'tags': ['Django', 'Square API', 'AWS SES', 'Lightsail'],
            'url': 'https://yomohirokan.com/',
        },
        {
            'icon': 'BotMessageSquare',
            'title': 'AIチャットボット基盤',
            'period': '2024',
            'desc': 'Claude API + RAGを活用した社内ナレッジQ&Aシステム。SSEによるストリーミング対応。',
            'tags': ['Claude API', 'RAG', 'Django', 'Vue3', 'SSE'],
        },
        {
            'icon': 'Sprout',
            'title': '農業IoTデータ可視化',
            'period': '2022〜2023',
            'desc': 'Raspberry Pi センサーデータのリアルタイム収集・可視化ダッシュボード。',
            'tags': ['Python', 'Raspberry Pi', 'Django', 'Chart.js'],
        },
    ],
    'profile_values': [
        {
            'emoji': '🚀',
            'title': '新規立ち上げが好き',
            'desc': '0→1フェーズが特に好き。アイデアをプロダクトに変える瞬間にエネルギーを感じます。',
        },
        {
            'emoji': '🤝',
            'title': '顧客主語で動く',
            'desc': 'ユーザーや顧客が何を必要としているかを軸に考える。技術はあくまで手段。',
        },
        {
            'emoji': '⚡',
            'title': '効率を極める',
            'desc': 'AI × ツール活用で開発速度を最大化。繰り返し作業を自動化するのが好きです。',
        },
    ],
    'profile_career': [
        {
            'year': '2000〜2004',
            'company': 'エコーシステムズ',
            'desc': '携帯電話テスターからキャリアをスタート。東京支店開設に伴い上京。Java / C++ を用いた Web・バッチシステム開発を担当。',
            'projects': ['HIS（旅行）', '読売新聞', '松井証券', '携帯電話テスト', 'Java', 'C++'],
        },
        {
            'year': '2004〜2021',
            'company': 'キヤノンITソリューションズ（旧キヤノンソフトウェア）',
            'desc': '組み込み・Web・モバイルと幅広い領域で17年間開発に従事。複合機・ロボット・プロジェクタ・ECU計測器など多様なドメインを経験。キャリア中盤で初代 Android を購入したことをきっかけに趣味のゲーム開発も開始。',
            'projects': [
                'キヤノン複合機制御', 'キヤノン内製ロボット', 'プロジェクタ iOS/Android',
                'SUBARU ECU計測器', '楽天証券 Web', '京セラ 燃料電池',
                'KEYENCE Windows アプリ', 'ミネベアミツミ 受発注システム',
                'C / C++', 'Java', 'C#', 'Swift', 'Android',
            ],
        },
        {
            'year': '2021〜現在',
            'company': 'Globalway — PF事業部ディレクター',
            'desc': 'Python / Django へ転向し Web サービス開発に専念。複数の大手 通信会社系案件を担当しながら、AI 活用・クラウドインフラ・チームマネジメントも推進。ディレクタとして新規顧客開拓を牽引。',
            'projects': [
                '某大手通信会社 トラフィックレポート', '某大手通信会社マイページ',
                '個別指導塾',
                'Python / Django', 'AWS', 'AI活用推進',
            ],
        },
    ],
    'profile_apps': [
        {
            'category': '予約・決済',
            'date': '2023年',
            'title': '東西南北（よもひろ）館',
            'desc': '旅館向けオンライン予約・決済システム。Square API 連携でクレジット決済に対応し、SMS通知・キャンセル自動処理・売上レポートを実装。Django + AWS で本番運用中。',
            'tags': ['Django', 'Square API', 'AWS Lightsail', 'PostgreSQL', 'SMS通知'],
            'url': 'https://yomohirokan.com/',
            'icon_url': '/images/yomohiro-kan-icon.png',
            'screenshot_url': '/images/yomohiro-kan-screenshot.png',
        },
        {
            'category': 'パズルゲーム',
            'date': '2016年3月',
            'title': 'モンスタースイーパー',
            'desc': '罠をしかけてモンスターを倒す、新感覚マインスイーパーRPG。ダジャモン（ダジャレモンスター）を探し出して図鑑コンプリートを目指す。STELLA STUDIO として個人開発・リリース。',
            'tags': ['Android', 'マインスイーパー', 'RPG', '個人開発'],
            'url': 'https://appget.com/appli/view/62986/',
            'icon_url': '/images/monster-sweeper-icon.png',
            'screenshot_url': '/images/monster-sweeper-screenshot.png',
        },
    ],
    'profile_skills': [
        {
            'label': 'Backend',
            'primary': True,
            'items': ['Python', 'Django', 'Django REST Framework', 'PostgreSQL', 'Square API'],
        },
        {
            'label': 'Frontend',
            'primary': True,
            'items': ['Vue 3', 'TypeScript', 'Tailwind CSS', 'Vite'],
        },
        {
            'label': 'Cloud / Infra',
            'primary': False,
            'items': ['AWS Lightsail', 'AWS SES', 'AWS S3', 'Docker', 'Nginx', 'Linux'],
        },
        {
            'label': 'AI',
            'primary': False,
            'items': ['Claude API', 'GPT-4', 'RAG', 'プロンプト設計', 'Cursor IDE', 'AI駆動開発'],
        },
        {
            'label': 'Past Experience',
            'primary': False,
            'items': ['Java', 'C', 'C++', 'C#', 'Swift', 'Android', 'iOS', 'Raspberry Pi', 'Chart.js'],
        },
    ],
}


def seed_content(apps, schema_editor):
    SiteText = apps.get_model('content', 'SiteText')
    ContentItem = apps.get_model('content', 'ContentItem')

    for key, value in SITE_TEXTS.items():
        SiteText.objects.get_or_create(key=key, defaults={'value': value})

    for section, items in CONTENT_ITEMS.items():
        for order, data in enumerate(items):
            ContentItem.objects.get_or_create(section=section, order=order, defaults={'data': data})


def remove_seed_content(apps, schema_editor):
    SiteText = apps.get_model('content', 'SiteText')
    ContentItem = apps.get_model('content', 'ContentItem')
    SiteText.objects.filter(key__in=SITE_TEXTS.keys()).delete()
    ContentItem.objects.filter(section__in=CONTENT_ITEMS.keys()).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('content', '0001_initial'),
    ]

    operations = [
        migrations.RunPython(seed_content, remove_seed_content),
    ]
