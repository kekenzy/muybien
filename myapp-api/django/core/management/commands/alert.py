from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from core.alerts import KINDS, flush_pending, send_alert


class Command(BaseCommand):
    help = 'アラート通知: test（テストを1通送る）/ flush（間隔を空けて溜めた通知をまとめて送る）'

    def add_arguments(self, parser):
        parser.add_argument('action', choices=['test', 'flush'])
        parser.add_argument('--kind', choices=KINDS, default='error', help='test で使う種類（既定: error）')

    def handle(self, *args, action, kind, **options):
        if not settings.ADMINS:
            raise CommandError('ALERT_EMAIL が空なので送り先がありません')
        if action == 'test':
            ok = send_alert(kind, 'テスト通知です（対応は不要です）', '\n'.join([
                '何が: 通知の仕組みのテストです',
                'URL: -',
                'アクセス元 IP: -',
                '自動でしたこと: なし',
            ]), force=True)
            if not ok:
                raise CommandError('送信に失敗しました。log/app.log とメール送信の設定を確認してください')
            self.stdout.write(f'テスト通知を {settings.ALERT_EMAIL} へ送りました')
            return
        sent = flush_pending()
        self.stdout.write(f'まとめて送った種類: {", ".join(sent) if sent else "なし"}')
