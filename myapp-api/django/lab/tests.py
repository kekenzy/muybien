import re
from datetime import timedelta
from unittest import mock

from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator
from django.core import mail
from django.core.cache import cache
from django.test import TestCase
from django.utils.encoding import force_bytes
from django.utils.http import urlsafe_base64_encode
from rest_framework.test import APIClient

from .invitations import password_reset_token_generator
from .models import Customer, DiaryEntry, LabTask, Memo, Role, RoleMenuPermission, UserProfile
from .ownership import visible_tasks_queryset

User = get_user_model()


class MeViewIsCustomerTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_is_customer_true_when_customer_profile_exists(self):
        user = User.objects.create_user(username='customer@example.com', password='password123')
        Customer.objects.create(name='顧客太郎', email='customer@example.com', user=user)
        self.client.force_authenticate(user=user)

        response = self.client.get('/v1/api/auth/me')

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()['is_customer'])

    def test_is_customer_false_for_staff_without_customer_profile(self):
        user = User.objects.create_user(username='staff@example.com', password='password123', is_staff=True)
        self.client.force_authenticate(user=user)

        response = self.client.get('/v1/api/auth/me')

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()['is_customer'])


class ReservationsMenuPermissionTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_user_without_role_cannot_read_reservations(self):
        user = User.objects.create_user(username='norole@example.com', password='password123')
        self.client.force_authenticate(user=user)

        response = self.client.get('/v1/api/lab/reservations')

        self.assertEqual(response.status_code, 403)

    def test_user_with_read_role_can_read_reservations(self):
        user = User.objects.create_user(username='reader@example.com', password='password123')
        role = Role.objects.create(name='予約閲覧')
        RoleMenuPermission.objects.create(role=role, menu_key='reservations', level=RoleMenuPermission.LEVEL_READ)
        profile = UserProfile.objects.create(user=user)
        profile.roles.add(role)
        self.client.force_authenticate(user=user)

        response = self.client.get('/v1/api/lab/reservations')

        self.assertEqual(response.status_code, 200)

    def test_superuser_can_write_reservation_settings(self):
        user = User.objects.create_superuser(username='admin@example.com', password='password123', email='admin@example.com')
        self.client.force_authenticate(user=user)

        response = self.client.get('/v1/api/lab/reservation-settings')

        self.assertEqual(response.status_code, 200)
        self.assertIn('settings', response.json())
        self.assertIn('rules', response.json())


class ChangePasswordTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.user = User.objects.create_user(username='staff', password='oldpassword', is_staff=True)
        self.client.force_authenticate(user=self.user)

    def test_change_password_with_correct_current_password(self):
        response = self.client.post(
            '/v1/api/auth/change-password',
            {'current_password': 'oldpassword', 'new_password': 'newpassword'},
            format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('newpassword'))

    def test_wrong_current_password_is_rejected(self):
        response = self.client.post(
            '/v1/api/auth/change-password',
            {'current_password': 'wrong', 'new_password': 'newpassword'},
            format='json',
        )
        self.assertEqual(response.status_code, 400)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('oldpassword'))

    def test_short_password_is_rejected(self):
        response = self.client.post(
            '/v1/api/auth/change-password',
            {'current_password': 'oldpassword', 'new_password': 'short'},
            format='json',
        )
        self.assertEqual(response.status_code, 400)

    def test_requires_login(self):
        response = APIClient().post(
            '/v1/api/auth/change-password',
            {'current_password': 'oldpassword', 'new_password': 'newpassword'},
            format='json',
        )
        self.assertEqual(response.status_code, 401)


class PasswordResetTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.user = User.objects.create_user(
            username='staff', email='staff@example.com', password='oldpassword', is_staff=True,
        )

    def _request(self, email):
        return self.client.post('/v1/api/auth/password-reset', {'email': email}, format='json')

    def _confirm(self, uid, token, password='newpassword'):
        return self.client.post(
            '/v1/api/auth/password-reset/confirm',
            {'uid': uid, 'token': token, 'password': password},
            format='json',
        )

    def _link_params(self):
        match = re.search(r'uid=([^&\s]+)&token=(\S+)', mail.outbox[-1].body)
        return match.group(1), match.group(2)

    def test_sends_reset_email_and_sets_new_password(self):
        response = self._request('STAFF@example.com')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn('/lab/reset-password?', mail.outbox[0].body)
        self.assertIn('ユーザー名: staff', mail.outbox[0].body)

        uid, token = self._link_params()
        self.assertEqual(self._confirm(uid, token).status_code, 200)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password('newpassword'))

        # 一度使ったリンクは無効
        self.assertEqual(self._confirm(uid, token, 'anotherpassword').status_code, 400)

    def test_unknown_email_returns_same_response_without_sending(self):
        known = self._request('staff@example.com')
        cache.clear()
        unknown = self._request('nobody@example.com')
        self.assertEqual(unknown.status_code, 200)
        self.assertEqual(unknown.json(), known.json())
        self.assertEqual(len(mail.outbox), 1)

    def test_inactive_and_customer_only_users_get_no_email(self):
        self.user.is_active = False
        self.user.save()
        customer_user = User.objects.create_user(
            username='customer@example.com', email='customer@example.com', password='password123',
        )
        Customer.objects.create(name='顧客', email='customer@example.com', user=customer_user)

        self._request('staff@example.com')
        self._request('customer@example.com')
        self.assertEqual(len(mail.outbox), 0)

    def test_same_email_is_not_sent_twice_within_cooldown(self):
        self._request('staff@example.com')
        self._request('staff@example.com')
        self.assertEqual(len(mail.outbox), 1)

    def test_invite_token_cannot_be_used_for_reset(self):
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        token = default_token_generator.make_token(self.user)
        self.assertEqual(self._confirm(uid, token).status_code, 400)

    def test_reset_token_cannot_be_used_on_invite_endpoint(self):
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        token = password_reset_token_generator.make_token(self.user)
        response = self.client.post(
            '/v1/api/lab/set-password', {'uid': uid, 'token': token, 'password': 'newpassword'}, format='json',
        )
        self.assertEqual(response.status_code, 400)

    def test_deactivated_user_cannot_use_reset_link(self):
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        token = password_reset_token_generator.make_token(self.user)
        self.user.is_active = False
        self.user.save()
        self.assertEqual(self._confirm(uid, token).status_code, 400)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)

    def test_reset_link_expires_after_one_hour(self):
        uid = urlsafe_base64_encode(force_bytes(self.user.pk))
        token = password_reset_token_generator.make_token(self.user)
        now = password_reset_token_generator._now()
        with mock.patch.object(password_reset_token_generator, '_now', return_value=now + timedelta(hours=2)):
            self.assertEqual(self._confirm(uid, token).status_code, 400)


class OwnershipScopeTests(TestCase):
    def setUp(self):
        self.alice = User.objects.create_user(username='alice', password='password123', is_staff=True)
        self.bob = User.objects.create_user(username='bob', password='password123', is_staff=True)
        self.client = APIClient()

    def test_diary_is_private_per_user(self):
        DiaryEntry.objects.create(owner=self.alice, date='2026-01-01', content='alice')
        DiaryEntry.objects.create(owner=self.bob, date='2026-01-01', content='bob')
        self.client.force_authenticate(user=self.alice)
        response = self.client.get('/v1/api/lab/diaries')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]['content'], 'alice')

    def test_memo_is_private_per_user(self):
        Memo.objects.create(owner=self.alice, title='a')
        Memo.objects.create(owner=self.bob, title='b')
        self.client.force_authenticate(user=self.alice)
        response = self.client.get('/v1/api/lab/memos')
        self.assertEqual(response.status_code, 200)
        self.assertEqual([m['title'] for m in response.json()], ['a'])

    def test_shared_task_exposes_linked_tree(self):
        parent = LabTask.objects.create(owner=self.alice, title='parent', is_shared=True)
        child = LabTask.objects.create(owner=self.alice, title='child', parent=parent)
        private = LabTask.objects.create(owner=self.alice, title='secret')
        visible = visible_tasks_queryset(self.bob)
        titles = set(visible.values_list('title', flat=True))
        self.assertEqual(titles, {'parent', 'child'})
        self.assertNotIn(private.id, visible.values_list('id', flat=True))

    def test_cannot_edit_others_shared_task(self):
        task = LabTask.objects.create(owner=self.alice, title='shared', is_shared=True)
        self.client.force_authenticate(user=self.bob)
        response = self.client.patch(f'/v1/api/lab/tasks/{task.id}', {'title': 'hacked'}, format='json')
        self.assertEqual(response.status_code, 403)


class JwtFlowTests(TestCase):
    """Django 5.2 / DRF / simplejwt を上げても、ログイン〜更新〜失効の振る舞いが変わらないことを確かめる。"""

    def setUp(self):
        cache.clear()
        self.client = APIClient()
        User.objects.create_user(username='jwt@example.com', password='password123', is_staff=True)

    def _login(self):
        response = self.client.post(
            '/v1/api/auth/login', {'username': 'jwt@example.com', 'password': 'password123'}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        return response.json()

    def test_login_returns_tokens_and_access_works(self):
        tokens = self._login()
        self.assertIn('access', tokens)
        self.assertIn('refresh', tokens)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {tokens['access']}")
        self.assertEqual(self.client.get('/v1/api/auth/me').status_code, 200)

    def test_wrong_password_is_401(self):
        response = self.client.post(
            '/v1/api/auth/login', {'username': 'jwt@example.com', 'password': 'wrong'}, format='json',
        )
        self.assertEqual(response.status_code, 401)

    def test_refresh_rotates_and_blacklists_old_token(self):
        tokens = self._login()
        response = self.client.post('/v1/api/auth/refresh', {'refresh': tokens['refresh']}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.json())
        self.assertNotEqual(response.json()['refresh'], tokens['refresh'])
        again = self.client.post('/v1/api/auth/refresh', {'refresh': tokens['refresh']}, format='json')
        self.assertEqual(again.status_code, 401)

    def test_logout_blacklists_refresh_token(self):
        tokens = self._login()
        response = self.client.post('/v1/api/auth/logout', {'refresh': tokens['refresh']}, format='json')
        self.assertEqual(response.status_code, 200)
        again = self.client.post('/v1/api/auth/refresh', {'refresh': tokens['refresh']}, format='json')
        self.assertEqual(again.status_code, 401)

    def test_invalid_access_token_is_401(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer invalid')
        self.assertEqual(self.client.get('/v1/api/auth/me').status_code, 401)


class ContactFormTests(TestCase):
    def test_contact_saves_and_sends_mail(self):
        from contact.models import ContactMessage

        response = APIClient().post('/v1/api/contact', {
            'name': '問合 太郎', 'email': 'guest@example.com', 'subject': '件名', 'message': '本文',
            'agree_privacy': True,
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(ContactMessage.objects.count(), 1)
        self.assertEqual(len(mail.outbox), 2)

    def test_contact_rejects_invalid_email(self):
        response = APIClient().post('/v1/api/contact', {
            'name': 'x', 'email': 'not-an-email', 'subject': 's', 'message': 'm',
        }, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertIn('email', response.json())
