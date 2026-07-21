from django.contrib import admin

from .models import Announcement, ContentItem, SiteText


@admin.register(Announcement)
class AnnouncementAdmin(admin.ModelAdmin):
    list_display = ['title', 'is_published', 'published_at', 'created_at']
    list_filter = ['is_published']
    search_fields = ['title', 'body']


@admin.register(SiteText)
class SiteTextAdmin(admin.ModelAdmin):
    list_display = ['key', 'updated_at']
    search_fields = ['key', 'value']


@admin.register(ContentItem)
class ContentItemAdmin(admin.ModelAdmin):
    list_display = ['section', 'order', 'is_active', 'updated_at']
    list_filter = ['section', 'is_active']
    ordering = ['section', 'order']
