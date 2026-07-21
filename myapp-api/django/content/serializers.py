from rest_framework import serializers

from .models import Announcement, ContentItem, SiteText


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


class ContentItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContentItem
        fields = [
            'id', 'section', 'order', 'is_active', 'image', 'image_secondary',
            'data', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
