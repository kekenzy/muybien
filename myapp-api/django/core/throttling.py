import time

from django.conf import settings
from django.core.cache import cache
from rest_framework.throttling import ScopedRateThrottle

from core.alerts import send_alert

TOP_IPS = 5


class AlertingScopedRateThrottle(ScopedRateThrottle):
    """ScopedRateThrottle と同じく止め、止めた件数が多いときに dos の通知を送る。

    スコープごとに ALERT_THROTTLE_WINDOW 秒の区切りで止めた件数を数え、
    ALERT_THROTTLE_THRESHOLD 件に達した時点で1回だけ通知する。
    """

    def allow_request(self, request, view):
        allowed = super().allow_request(request, view)
        if not allowed and self.rate is not None:
            try:
                self._record_rejection(request)
            except Exception:
                pass
        return allowed

    def _record_rejection(self, request):
        window = settings.ALERT_THROTTLE_WINDOW
        bucket = int(time.time() // window)
        count_key = f'alert:throttle:{self.scope}:{bucket}'
        ips_key = f'alert:throttle-ips:{self.scope}:{bucket}'
        cache.add(count_key, 0, window * 2)
        count = cache.incr(count_key)

        ip = self.get_ident(request)
        ips = cache.get(ips_key) or {}
        ips[ip] = ips.get(ip, 0) + 1
        cache.set(ips_key, ips, window * 2)

        if count != settings.ALERT_THROTTLE_THRESHOLD:
            return
        top = sorted(ips.items(), key=lambda item: -item[1])[:TOP_IPS]
        minutes = window // 60
        body = '\n'.join([
            f'何が: 回数制限（{self.scope}: {self.rate}）で止めたリクエストが {minutes} 分間に {count} 件に達しました',
            f'URL: {request.method} {request.path}',
            'アクセス元 IP（止めた件数）:',
            *[f'  {addr}: {n} 件' for addr, n in top],
            f'自動でしたこと: 429 を返して受け付けていません（この区切りの間は引き続き止めます）',
            '対応の目安: 同じ IP が続くなら nginx・fail2ban で遮断されているか確認してください',
        ])
        send_alert('dos', f'回数制限の多発 {self.scope} {count}件/{minutes}分 ({top[0][0]} ほか)', body)
