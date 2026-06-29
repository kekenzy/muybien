from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    ContactDetailView,
    ContactListView,
    LabTokenObtainPairView,
    MeView,
)

urlpatterns = [
    path('auth/login', LabTokenObtainPairView.as_view()),
    path('auth/refresh', TokenRefreshView.as_view()),
    path('auth/me', MeView.as_view()),
    path('lab/contacts', ContactListView.as_view()),
    path('lab/contacts/<int:pk>', ContactDetailView.as_view()),
]
