"""異常・攻撃の通知メール（件名は全プロジェクト共通の形）。

件名: [ALERT][MuyBienBase][<種類>] <要約>
種類: dos / intrusion / error / down

同じ種類は ALERT_COOLDOWN_SECONDS に1通まで。間に起きたものは溜めておき、次の通知
（または `manage.py alert flush`）にまとめて載せる。本文にはパスワード・個人情報・秘密の値を書かない。
"""
import logging
import socket
import time
import traceback

from django.conf import settings
from django.core.cache import cache
from django.core.mail import mail_admins
from django.utils import timezone
from django.utils.log import AdminEmailHandler

logger = logging.getLogger('core.alerts')

KINDS = ('dos', 'intrusion', 'error', 'down')
PENDING_KEEP = 20
PENDING_TTL = 7 * 24 * 60 * 60

# DB が落ちてキャッシュ（DB キャッシュ）を使えないときの、ワーカー内だけの間隔管理
_local_last_sent = {}


def build_subject(kind, summary):
    return f'[ALERT][{settings.ALERT_PROJECT}][{kind}] {summary}'


def server_name():
    return settings.ALERT_SERVER_NAME or socket.gethostname()


def client_ip(request):
    """DRF の NUM_PROXIES=1 と同じく、X-Forwarded-For の末尾（nginx が付けた値）を使う。"""
    if request is None:
        return '-'
    xff = request.META.get('HTTP_X_FORWARDED_FOR', '')
    if xff:
        return xff.split(',')[-1].strip()
    return request.META.get('REMOTE_ADDR', '-')


def _cooldown_key(kind):
    return f'alert:cooldown:{kind}'


def _pending_key(kind):
    return f'alert:pending:{kind}'


def _remember_pending(kind, summary):
    pending = cache.get(_pending_key(kind)) or {'count': 0, 'items': []}
    pending['count'] += 1
    pending['items'] = (pending['items'] + [f'{timezone.localtime():%Y-%m-%d %H:%M:%S} {summary}'])[-PENDING_KEEP:]
    cache.set(_pending_key(kind), pending, PENDING_TTL)


def _pending_text(pending):
    if not pending or not pending['count']:
        return ''
    lines = [
        '',
        f'--- 前回の通知のあと、間隔を空けるために送らなかった同じ種類の通知: {pending["count"]} 件 ---',
        *pending['items'],
    ]
    if pending['count'] > len(pending['items']):
        lines.append(f'（ほか {pending["count"] - len(pending["items"])} 件は省略）')
    return '\n'.join(lines)


def _pop_pending(kind):
    try:
        pending = cache.get(_pending_key(kind))
        cache.delete(_pending_key(kind))
        return pending
    except Exception:
        return None


def _send(kind, summary, body):
    pending = _pop_pending(kind)
    text = '\n'.join([
        f'日時: {timezone.localtime():%Y-%m-%d %H:%M:%S %Z}',
        f'サーバー: {server_name()}',
        f'サイト: {settings.FRONTEND_BASE_URL}',
        f'種類: {kind}',
        '',
        body.rstrip(),
        _pending_text(pending),
    ]).rstrip() + '\n'
    try:
        mail_admins(build_subject(kind, summary), text, fail_silently=False)
    except Exception:
        logger.exception('アラートメールの送信に失敗しました（%s: %s）', kind, summary)
        return False
    return True


def send_alert(kind, summary, body, *, force=False):
    """通知を送る。間隔を空ける期間中なら溜めて False を返す。force=True は間隔を無視する（テスト用）。"""
    if kind not in KINDS:
        raise ValueError(f'unknown alert kind: {kind}')
    if not settings.ADMINS:
        return False
    if force:
        return _send(kind, summary, body)
    try:
        if not cache.add(_cooldown_key(kind), 1, settings.ALERT_COOLDOWN_SECONDS):
            _remember_pending(kind, summary)
            return False
    except Exception:
        now = time.monotonic()
        if now - _local_last_sent.get(kind, -float('inf')) < settings.ALERT_COOLDOWN_SECONDS:
            return False
        _local_last_sent[kind] = now
        body += '\n\n（キャッシュ（DB）に接続できないため、まとめ件数は数えていません）'
    return _send(kind, summary, body)


def flush_pending():
    """溜まっている通知を、間隔が空いた種類だけまとめて送る。送った種類のリストを返す。"""
    sent = []
    for kind in KINDS:
        pending = cache.get(_pending_key(kind))
        if not pending or not pending['count']:
            continue
        if not cache.add(_cooldown_key(kind), 1, settings.ALERT_COOLDOWN_SECONDS):
            continue
        if _send(kind, f'まとめ: {pending["count"]} 件', '間隔を空けている間に起きた通知のまとめです。'):
            sent.append(kind)
    return sent


class AlertAdminEmailHandler(AdminEmailHandler):
    """500 エラーを ADMINS へ知らせる。

    標準の AdminEmailHandler は本文にリクエストの中身やローカル変数を載せるため、
    個人情報やトークンが入りうる。ここでは場所・例外・スタックトレース（変数なし）だけを書く。
    """

    def emit(self, record):
        try:
            request = getattr(record, 'request', None)
            status = getattr(record, 'status_code', None) or 500
            method = getattr(request, 'method', '-')
            path = getattr(request, 'path', '-')
            exc_text = ''
            exc_name = record.levelname
            if record.exc_info and record.exc_info[1] is not None:
                exc_name = type(record.exc_info[1]).__name__
                exc_text = ''.join(traceback.format_exception(*record.exc_info))
            body = '\n'.join([
                f'何が: {status} エラー（{exc_name}）',
                f'URL: {method} {path}',
                f'アクセス元 IP: {client_ip(request)}',
                '自動でしたこと: なし（エラー応答を返しました）',
                '',
                'ログ:',
                record.getMessage(),
                '',
                exc_text,
            ])
            send_alert('error', f'{status} {method} {path} ({exc_name})'[:150], body)
        except Exception:
            self.handleError(record)
