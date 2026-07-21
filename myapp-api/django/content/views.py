from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from lab.permissions import MenuPermission

from .models import Announcement, ContentItem, SiteText
from .serializers import AnnouncementSerializer, ContentItemSerializer, SiteTextSerializer

# --- Lab管理用（要認証・要権限） ---


class AnnouncementListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'announcements'
    serializer_class = AnnouncementSerializer
    queryset = Announcement.objects.all()


class AnnouncementDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'announcements'
    serializer_class = AnnouncementSerializer
    queryset = Announcement.objects.all()


class SiteTextListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'site_content'
    serializer_class = SiteTextSerializer
    queryset = SiteText.objects.all()


class SiteTextDetailView(APIView):
    """keyでの取得・更新（存在しなければ作成してから更新するupsert）"""

    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'site_content'

    def patch(self, request, key):
        text, _ = SiteText.objects.get_or_create(key=key)
        serializer = SiteTextSerializer(text, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class ContentItemListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'site_content'
    serializer_class = ContentItemSerializer

    def get_queryset(self):
        queryset = ContentItem.objects.all()
        section = self.request.query_params.get('section')
        if section:
            queryset = queryset.filter(section=section)
        return queryset


class ContentItemDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'site_content'
    serializer_class = ContentItemSerializer
    queryset = ContentItem.objects.all()


# --- 公開用（permission_classes省略でプロジェクト既定のAllowAnyに乗る） ---


class PublicAnnouncementListView(generics.ListAPIView):
    serializer_class = AnnouncementSerializer

    def get_queryset(self):
        queryset = Announcement.objects.filter(is_published=True).order_by('-published_at', '-created_at')
        limit = self.request.query_params.get('limit')
        if limit and limit.isdigit():
            queryset = queryset[:int(limit)]
        return queryset


class PublicAnnouncementDetailView(generics.RetrieveAPIView):
    serializer_class = AnnouncementSerializer
    queryset = Announcement.objects.filter(is_published=True)


class PublicSiteContentView(APIView):
    """公開サイトが1回のリクエストで全セクション分のテキスト・項目を取得するための集約API"""

    def get(self, request):
        texts = {text.key: text.value for text in SiteText.objects.all()}
        items = {}
        for item in ContentItem.objects.filter(is_active=True):
            items.setdefault(item.section, []).append(ContentItemSerializer(item).data)
        return Response({'texts': texts, 'items': items})
