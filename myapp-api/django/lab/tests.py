from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

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
