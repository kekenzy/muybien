import re

from rest_framework import serializers

from .models import Announcement, ContentItem, SiteText


# 公開サイトでリンク（href）に使う URL は、http(s)・mailto・サイト内の相対パスだけを受け付ける。
# javascript: などを登録されると、公開サイトを開いた人のブラウザで実行されてしまうため。
_SAFE_URL_RE = re.compile(r'^(https?://|mailto:|/(?!/))', re.IGNORECASE)


def _is_url_key(key):
    return key == 'url' or key.endswith('_url')


def _validate_url(value, label):
    if value in (None, ''):
        return
    if not isinstance(value, str) or not _SAFE_URL_RE.match(value.strip()):
        raise serializers.ValidationError(
            f'{label} は http(s)://・mailto: またはサイト内のパス（/ で始まる）で入力してください。'
        )


class AnnouncementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Announcement
        fields = [
            'id', 'title', 'body', 'cover_image', 'is_published',
            'published_at', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SiteTextSerializer(serializers.ModelSerializer):
    class Meta:
        model = SiteText
        fields = ['id', 'key', 'value', 'updated_at']
        read_only_fields = ['id', 'updated_at']

    def validate(self, attrs):
        key = attrs.get('key', getattr(self.instance, 'key', ''))
        if _is_url_key(key) and 'value' in attrs:
            _validate_url(attrs['value'], key)
        return attrs


class ContentItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContentItem
        fields = [
            'id', 'section', 'order', 'is_active', 'image', 'image_secondary',
            'data', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_data(self, value):
        if isinstance(value, dict):
            for key, item in value.items():
                if _is_url_key(key):
                    _validate_url(item, key)
        return value
