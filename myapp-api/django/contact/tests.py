from django.test import TestCase
from rest_framework.test import APIClient

from .models import ContactMessage

URL = '/v1/api/contact'
VALID = {
    'name': '山田 太郎',
    'email': 'taro@example.com',
    'subject': 'ご相談',
    'message': 'よろしくお願いします。',
}


class ContactPrivacyAgreementTests(TestCase):
    # 同意ありで受け付けるケースは lab.tests.ContactFormTests で確認している
    def setUp(self):
        self.client = APIClient()

    def test_rejects_without_agreement_field(self):
        response = self.client.post(URL, VALID, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('agree_privacy', response.data)
        self.assertEqual(ContactMessage.objects.count(), 0)

    def test_rejects_when_not_agreed(self):
        response = self.client.post(URL, {**VALID, 'agree_privacy': False}, format='json')

        self.assertEqual(response.status_code, 400)
        self.assertIn('agree_privacy', response.data)
        self.assertEqual(ContactMessage.objects.count(), 0)
