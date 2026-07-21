from django.urls import path

from .views import (
    AnnouncementDetailView,
    AnnouncementListCreateView,
    ContentItemDetailView,
    ContentItemListCreateView,
    PublicAnnouncementDetailView,
    PublicAnnouncementListView,
    PublicSiteContentView,
    SiteTextDetailView,
    SiteTextListView,
)

urlpatterns = [
    path('lab/announcements', AnnouncementListCreateView.as_view()),
    path('lab/announcements/<int:pk>', AnnouncementDetailView.as_view()),
    path('lab/site-texts', SiteTextListView.as_view()),
    path('lab/site-texts/<str:key>', SiteTextDetailView.as_view()),
    path('lab/content-items', ContentItemListCreateView.as_view()),
    path('lab/content-items/<int:pk>', ContentItemDetailView.as_view()),
    path('announcements', PublicAnnouncementListView.as_view()),
    path('announcements/<int:pk>', PublicAnnouncementDetailView.as_view()),
    path('site-content', PublicSiteContentView.as_view()),
]
