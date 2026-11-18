from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from .models import SECTION_CHOICES, ContentItem, SiteText

User = get_user_model()


class ContentUrlValidationTests(TestCase):
    """公開サイトのリンクに使う URL に javascript: などを登録できないこと。"""

    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.client.force_authenticate(User.objects.create_user(username='staff', password='x', is_staff=True))

    def _create_item(self, data):
        return self.client.post('/v1/api/lab/content-items', {'section': SECTION_CHOICES[0][0], 'data': data}, format='json')

    def test_rejects_javascript_url_in_item(self):
        before = ContentItem.objects.count()
        for bad in ['javascript:alert(1)', ' JavaScript:alert(1)', 'data:text/html,x', '//evil.example.com', 'vbscript:x']:
            response = self._create_item({'title': 'x', 'url': bad})
            self.assertEqual(response.status_code, 400, bad)
        self.assertEqual(ContentItem.objects.count(), before)

    def test_rejects_javascript_in_other_url_keys(self):
        self.assertEqual(self._create_item({'icon_url': 'javascript:alert(1)'}).status_code, 400)

    def test_accepts_http_mailto_and_site_paths(self):
        for good in ['https://example.com/', 'http://example.com', 'mailto:a@example.com', '/picsco/index.html', '']:
            self.assertEqual(self._create_item({'title': 'x', 'url': good}).status_code, 201, good)

    def test_site_text_url_is_validated(self):
        response = self.client.patch('/v1/api/lab/site-texts/profile_blog_url', {'value': 'javascript:alert(1)'}, format='json')
        self.assertEqual(response.status_code, 400)
        response = self.client.patch('/v1/api/lab/site-texts/profile_blog_url', {'value': 'https://example.com/'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(SiteText.objects.get(key='profile_blog_url').value, 'https://example.com/')

    def test_non_url_site_text_is_not_restricted(self):
        response = self.client.patch('/v1/api/lab/site-texts/profile_tagline', {'value': 'javascript: 入門'}, format='json')
        self.assertEqual(response.status_code, 200)
