from django.conf import settings
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode


def build_set_password_url(user, *, portal=False):
    uid = urlsafe_base64_encode(force_bytes(user.pk))
    token = default_token_generator.make_token(user)
    path = '/portal/set-password' if portal else '/lab/set-password'
    return f'{settings.FRONTEND_BASE_URL}{path}?uid={uid}&token={token}'


def send_invite_email(user, intro='永井のLabへのアカウントが作成されました。', *, portal=False):
    if not user.email:
        raise ValueError('メールアドレスが未設定です。')
    url = build_set_password_url(user, portal=portal)
    if portal:
        subject = '【MuyBien】お客様ポータル招待'
        link_guide = '以下のリンクからパスワードを設定し、お客様ポータルへログインしてください。'
    else:
        subject = '【MuyBien Lab】アカウント招待'
        link_guide = '以下のリンクからパスワードを設定してログインしてください。'
    send_mail(
        subject=subject,
        message=(
            f'{intro}\n\n'
            f'{link_guide}\n'
            f'{url}\n\n'
            f'このリンクは第三者に共有しないでください。'
        ),
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[user.email],
        fail_silently=False,
    )


def resend_invite_email(user, intro=None, *, portal=False):
    """期限切れリンク救済用。未設定パスワードならハッシュを回して旧リンクを無効化する。"""
    if not user.has_usable_password():
        user.set_unusable_password()
        user.save(update_fields=['password'])
    if intro is None:
        intro = (
            'お客様ポータルのパスワード設定リンクを再送します。'
            if portal
            else '永井のLabのパスワード設定リンクを再送します。'
        )
    send_invite_email(user, intro=intro, portal=portal)
