from contact.models import ContactMessage
from django.contrib.auth import get_user_model
from rest_framework import generics, status
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import ContactAdminSerializer

User = get_user_model()


class LabTokenObtainPairView(TokenObtainPairView):
    """管理者ログイン（is_staff のユーザーのみ）"""

    def post(self, request, *args, **kwargs):
        username = request.data.get('username', '')
        password = request.data.get('password', '')

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'detail': 'ユーザー名またはパスワードが正しくありません。'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_staff:
            return Response({'detail': '管理者権限がありません。'}, status=status.HTTP_403_FORBIDDEN)

        if not user.check_password(password):
            return Response({'detail': 'ユーザー名またはパスワードが正しくありません。'}, status=status.HTTP_401_UNAUTHORIZED)

        return super().post(request, *args, **kwargs)


class MeView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        user = request.user
        return Response({
            'username': user.username,
            'email': user.email,
            'is_staff': user.is_staff,
        })


class ContactListView(generics.ListAPIView):
    permission_classes = [IsAdminUser]
    serializer_class = ContactAdminSerializer
    queryset = ContactMessage.objects.all()


class ContactDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAdminUser]
    serializer_class = ContactAdminSerializer
    queryset = ContactMessage.objects.all()
    http_method_names = ['get', 'patch', 'head', 'options']
