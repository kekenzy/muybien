import logging
from io import StringIO
from unittest import mock

from django.contrib.auth import get_user_model
from django.core import mail
from django.core.cache import cache
from django.core.management import call_command
from django.test import RequestFactory, TestCase, override_settings
from rest_framework.test import APIClient

from core.alerts import AlertAdminEmailHandler, send_alert

User = get_user_model()

ALERT_SETTINGS = dict(
    ADMINS=[('MuyBien Alert', 'kekenzy@gmail.com')],
    ALERT_SERVER_NAME='test-server',
    ALERT_COOLDOWN_SECONDS=900,
)


@override_settings(**ALERT_SETTINGS)
class SendAlertTests(TestCase):
    def setUp(self):
        cache.clear()

    def test_subject_follows_shared_format(self):
        self.assertTrue(send_alert('dos', '要約', '本文'))

        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertEqual(message.subject, '[ALERT][MuyBienBase][dos] 要約')
        self.assertEqual(message.to, ['kekenzy@gmail.com'])
        self.assertIn('サーバー: test-server', message.body)

    def test_same_kind_is_held_during_cooldown_and_sent_with_next(self):
        send_alert('dos', '1回目', '本文')
        self.assertFalse(send_alert('dos', '2回目', '本文'))
        self.assertFalse(send_alert('dos', '3回目', '本文'))
        self.assertEqual(len(mail.outbox), 1)

        cache.delete('alert:cooldown:dos')
        send_alert('dos', '4回目', '本文')

        self.assertEqual(len(mail.outbox), 2)
        self.assertIn('送らなかった同じ種類の通知: 2 件', mail.outbox[1].body)
        self.assertIn('2回目', mail.outbox[1].body)

    def test_other_kind_is_not_held(self):
        send_alert('dos', 'a', '本文')
        send_alert('intrusion', 'b', '本文')

        self.assertEqual(len(mail.outbox), 2)

    def test_flush_sends_held_alerts_after_cooldown(self):
        send_alert('error', '1回目', '本文')
        send_alert('error', '2回目', '本文')
        cache.delete('alert:cooldown:error')

        call_command('alert', 'flush', stdout=StringIO())

        self.assertEqual(len(mail.outbox), 2)
        self.assertEqual(mail.outbox[1].subject, '[ALERT][MuyBienBase][error] まとめ: 1 件')

    def test_test_command_ignores_cooldown(self):
        send_alert('error', '本物', '本文')

        call_command('alert', 'test', stdout=StringIO())

        self.assertEqual(len(mail.outbox), 2)
        self.assertIn('テスト通知', mail.outbox[1].subject)

    @override_settings(ADMINS=[])
    def test_no_admins_sends_nothing(self):
        self.assertFalse(send_alert('dos', 'a', '本文'))
        self.assertEqual(len(mail.outbox), 0)

    def test_falls_back_when_cache_is_unavailable(self):
        with mock.patch('core.alerts.cache.add', side_effect=Exception('db down')):
            self.assertTrue(send_alert('down', 'a', '本文'))
            self.assertFalse(send_alert('down', 'b', '本文'))
        self.assertEqual(len(mail.outbox), 1)


@override_settings(**ALERT_SETTINGS)
class ErrorHandlerTests(TestCase):
    def setUp(self):
        cache.clear()

    def test_500_mail_has_location_but_not_request_contents(self):
        request = RequestFactory().post(
            '/v1/api/contact', data='{"email": "secret@example.com"}', content_type='application/json',
            HTTP_AUTHORIZATION='Bearer secret-token', HTTP_X_FORWARDED_FOR='203.0.113.5',
        )
        try:
            raise ValueError('boom')
        except ValueError:
            import sys
            exc_info = sys.exc_info()
        record = logging.LogRecord('django.request', logging.ERROR, __file__, 1,
                                   'Internal Server Error: %s', ('/v1/api/contact',), exc_info)
        record.request = request
        record.status_code = 500

        AlertAdminEmailHandler().emit(record)

        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertEqual(message.subject, '[ALERT][MuyBienBase][error] 500 POST /v1/api/contact (ValueError)')
        self.assertIn('203.0.113.5', message.body)
        self.assertIn('ValueError: boom', message.body)
        self.assertNotIn('secret-token', message.body)
        self.assertNotIn('secret@example.com', message.body)


@override_settings(**ALERT_SETTINGS, ALERT_THROTTLE_THRESHOLD=3)
class ThrottleAlertTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def _contact(self):
        return self.client.post('/v1/api/contact', {}, format='json', REMOTE_ADDR='198.51.100.7')

    def test_alerts_once_when_rejections_reach_threshold(self):
        for _ in range(5):
            self._contact()
        self.assertEqual(len(mail.outbox), 0)

        statuses = [self._contact().status_code for _ in range(4)]

        self.assertEqual(statuses, [429, 429, 429, 429])
        self.assertEqual(len(mail.outbox), 1)
        message = mail.outbox[0]
        self.assertTrue(message.subject.startswith('[ALERT][MuyBienBase][dos] 回数制限の多発 contact 3件/10分'))
        self.assertIn('198.51.100.7: 3 件', message.body)


@override_settings(**ALERT_SETTINGS)
class LoginLockAlertTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        User.objects.create_user(username='admin@example.com', password='correct-password', is_staff=True)

    def test_alerts_when_account_gets_locked(self):
        for i in range(10):
            # 回数制限（10/分）に当たらないよう、IP を変える
            self.client.post('/v1/api/auth/login', {'username': 'admin@example.com', 'password': 'wrong'},
                             format='json', REMOTE_ADDR=f'192.0.2.{i}')

        alerts = [m for m in mail.outbox if m.subject.startswith('[ALERT]')]
        self.assertEqual(len(alerts), 1)
        self.assertTrue(alerts[0].subject.startswith('[ALERT][MuyBienBase][intrusion] '))
        self.assertIn('ad***', alerts[0].body)
        self.assertNotIn('admin@example.com', alerts[0].body)
        self.assertNotIn('wrong', alerts[0].body)
