from datetime import date, time, timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from lab.models import Customer
from rest_framework.test import APIClient

from .availability import compute_available_slots, is_slot_available
from .models import Appointment, AvailabilityRule, ReservationSettings

User = get_user_model()


class AvailabilityLogicTests(TestCase):
    def setUp(self):
        ReservationSettings.objects.create(pk=1, slot_minutes=60, min_notice_hours=1, max_advance_days=30)
        self.monday = self._next_weekday(0)
        AvailabilityRule.objects.create(weekday=0, start_time=time(10, 0), end_time=time(12, 0))

    @staticmethod
    def _next_weekday(weekday):
        today = timezone.localdate()
        days_ahead = (weekday - today.weekday()) % 7
        days_ahead = days_ahead or 7  # 今日ではなく必ず先の同曜日にする
        return today + timedelta(days=days_ahead)

    def test_generates_slots_within_business_hours(self):
        slots = compute_available_slots(self.monday, self.monday)
        self.assertEqual(len(slots), 2)
        self.assertEqual(slots[0]['start_at'].time(), time(10, 0))
        self.assertEqual(slots[1]['start_at'].time(), time(11, 0))

    def test_excludes_slot_overlapping_existing_appointment(self):
        tz = timezone.get_current_timezone()
        start = timezone.make_aware(timezone.datetime.combine(self.monday, time(10, 0)), tz)
        customer = Customer.objects.create(name='テスト太郎', email='taro@example.com')
        Appointment.objects.create(customer=customer, start_at=start, end_at=start + timedelta(hours=1))

        slots = compute_available_slots(self.monday, self.monday)
        self.assertEqual(len(slots), 1)
        self.assertEqual(slots[0]['start_at'].time(), time(11, 0))

    def test_is_slot_available_rejects_outside_business_hours(self):
        tz = timezone.get_current_timezone()
        start = timezone.make_aware(timezone.datetime.combine(self.monday, time(13, 0)), tz)
        self.assertFalse(is_slot_available(start, start + timedelta(hours=1)))

    def test_is_slot_available_rejects_within_min_notice(self):
        start = timezone.now() + timedelta(minutes=30)
        self.assertFalse(is_slot_available(start, start + timedelta(hours=1)))


class PortalPermissionTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_staff_without_customer_profile_is_rejected(self):
        staff_user = User.objects.create_user(username='staff@example.com', password='password123', is_staff=True)
        self.client.force_authenticate(user=staff_user)
        response = self.client.get('/v1/api/portal/appointments')
        self.assertEqual(response.status_code, 403)

    def test_customer_can_list_own_appointments(self):
        user = User.objects.create_user(username='customer@example.com', password='password123')
        Customer.objects.create(name='顧客太郎', email='customer@example.com', user=user)
        self.client.force_authenticate(user=user)
        response = self.client.get('/v1/api/portal/appointments')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), [])

    def test_anonymous_is_rejected(self):
        response = self.client.get('/v1/api/portal/appointments')
        self.assertEqual(response.status_code, 401)


class PortalPaymentMethodTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='pay@example.com', password='password123')
        self.customer = Customer.objects.create(name='決済太郎', email='pay@example.com', user=self.user)
        self.client.force_authenticate(user=self.user)

    def test_list_payment_methods_without_stripe_customer_returns_empty(self):
        response = self.client.get('/v1/api/portal/payment-methods')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), [])

    @patch('portal.stripe_client.stripe.Customer.create')
    @patch('portal.stripe_client.stripe.SetupIntent.create')
    def test_setup_intent_creates_stripe_customer(self, mock_setup_intent, mock_customer_create):
        mock_customer_create.return_value = type('obj', (), {'id': 'cus_test123'})
        mock_setup_intent.return_value = type('obj', (), {'client_secret': 'seti_test_secret'})

        response = self.client.post('/v1/api/portal/payment-methods/setup-intent')

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['client_secret'], 'seti_test_secret')
        self.customer.refresh_from_db()
        self.assertEqual(self.customer.stripe_customer_id, 'cus_test123')
