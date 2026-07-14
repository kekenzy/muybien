from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode


def build_set_password_url(user):
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    return f'{settings.FRONTEND_BASE_URL}/lab/set-password?uid={uid}&token={token}'


def send_invite_email(user, intro='永井のLabへのアカウントが作成されました。'):
    url = build_set_password_url(user)
    send_mail(
        subject='【MuyBien Lab】アカウント招待',
        message=(
            f'{intro}\n\n'
            f'以下のリンクからパスワードを設定してログインしてください。\n'
            f'{url}\n\n'
            f'このリンクは第三者に共有しないでください。'
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )
