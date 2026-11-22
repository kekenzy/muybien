import os
from datetime import timedelta, timezone

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

DEBUG = False
# Django Admin は本番では既定で無効。必要なときだけ環境変数 ADMIN_ENABLED=true で一時的に有効にする
ADMIN_ENABLED = os.environ.get('ADMIN_ENABLED', '').strip().lower() in ('1', 'true', 'yes')
ALLOWED_HOSTS = ['*']
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

WSGI_APPLICATION = 'core.wsgi.application'

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    'rest_framework_simplejwt.token_blacklist',
    'contact',
    'lab',
    'portal',
    'content',
    'core',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

LANGUAGE_CODE = 'ja'
TIME_ZONE = 'Asia/Tokyo'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    # ScopedRateThrottle を付けたビューだけに効く。本番は nginx 1段なので X-Forwarded-For の末尾を
    # クライアントIPとして扱う（先頭はクライアントが偽装できるため）
    'NUM_PROXIES': 1,
    'DEFAULT_THROTTLE_RATES': {
        'login': '10/minute',
        'contact': '5/hour',
        'password_reset': '5/hour',
        'password_change': '10/hour',
    },
}

# アクセストークンは短命にし、refresh はローテーションのたびに古いものを失効させる
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}

# レート制限・ログイン失敗回数を gunicorn の全ワーカーで共有するため DB キャッシュにする
# （テーブルは manage.py createcachetable で作成）
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.db.DatabaseCache',
        'LOCATION': 'django_cache',
    },
}

# Email（環境変数で上書き）
_raw_email_backend = (os.environ.get('EMAIL_BACKEND') or '').strip()
EMAIL_BACKEND = _raw_email_backend or 'django.core.mail.backends.console.EmailBackend'
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'no-reply@example.com')
EMAIL_HOST = (os.environ.get('EMAIL_HOST') or '').strip() or None
if EMAIL_HOST:
    EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
    EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
    EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
    EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'True').lower() in ['true', '1', 'yes']
    EMAIL_USE_SSL = os.environ.get('EMAIL_USE_SSL', 'False').lower() in ['true', '1', 'yes']

CONTACT_NOTIFY_EMAIL = os.environ.get('CONTACT_NOTIFY_EMAIL', 'stellastudio4xx@gmail.com')

# Lab招待メール内のリンク生成に使うフロントエンドのベースURL
FRONTEND_BASE_URL = os.environ.get('FRONTEND_BASE_URL', 'http://localhost:5173')

# 顧客ポータルの決済（カード登録）用Stripe設定
STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY', '')
STRIPE_PUBLISHABLE_KEY = os.environ.get('STRIPE_PUBLISHABLE_KEY', '')

# 異常・攻撃の通知（core/alerts.py）。件名は [ALERT][MuyBienBase][dos|intrusion|error|down] 要約
# 届いたメールは司令塔の定期タスクが Gmail で読むので、宛先と件名の形は変えないこと
ALERT_EMAIL = os.environ.get('ALERT_EMAIL', 'kekenzy@gmail.com').strip()
ALERT_PROJECT = 'MuyBienBase'
ALERT_SERVER_NAME = os.environ.get('ALERT_SERVER_NAME', '').strip()
ALERT_COOLDOWN_SECONDS = int(os.environ.get('ALERT_COOLDOWN_SECONDS', 15 * 60))
# 回数制限で止めた件数が、10分間に20件（スコープごと）に達したら dos を通知する
ALERT_THROTTLE_WINDOW = 10 * 60
ALERT_THROTTLE_THRESHOLD = int(os.environ.get('ALERT_THROTTLE_THRESHOLD', 20))
ADMINS = [('MuyBien Alert', ALERT_EMAIL)] if ALERT_EMAIL else []
SERVER_EMAIL = DEFAULT_FROM_EMAIL
EMAIL_SUBJECT_PREFIX = ''

LOG_DIR = os.path.join(BASE_DIR, 'log')
os.makedirs(LOG_DIR, exist_ok=True)

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {'class': 'logging.StreamHandler'},
        'file': {
            'class': 'logging.FileHandler',
            'filename': os.path.join(LOG_DIR, 'app.log'),
        },
        'alert_mail': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'core.alerts.AlertAdminEmailHandler',
        },
    },
    'filters': {
        'require_debug_false': {'()': 'django.utils.log.RequireDebugFalse'},
    },
    'loggers': {
        'django': {'handlers': ['console', 'file'], 'level': 'INFO'},
        # 500 エラー（django.request の ERROR）だけを通知する。4xx は WARNING なので送らない
        'django.request': {'handlers': ['alert_mail'], 'level': 'ERROR', 'propagate': True},
        'contact': {'handlers': ['console', 'file'], 'level': 'DEBUG', 'propagate': False},
        'core': {'handlers': ['console', 'file'], 'level': 'INFO', 'propagate': False},
    },
}
