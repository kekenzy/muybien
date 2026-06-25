from core.settings.common import *  # noqa

DEBUG = True

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('RDS_DB_NAME', 'muybiendb'),
        'USER': os.environ.get('RDS_USERNAME', 'postgres'),
        'PASSWORD': os.environ.get('RDS_PASSWORD', 'password'),
        'HOST': os.environ.get('RDS_HOSTNAME', 'myapp-db'),
        'PORT': os.environ.get('RDS_PORT', '5432'),
    }
}

CORS_ALLOWED_ORIGINS = [
    'http://localhost:5173',
    'http://localhost:8080',
]
CORS_ALLOW_CREDENTIALS = True
