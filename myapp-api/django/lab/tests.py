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
from .models import Customer, Role, RoleMenuPermission, UserProfile

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
