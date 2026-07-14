from contact.models import ContactMessage
from django.contrib.auth import get_user_model
from django.contrib.auth.tokens import default_token_generator
from django.utils.encoding import force_str
from django.utils.http import urlsafe_base64_decode
from rest_framework import generics, status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .invitations import send_invite_email
from .models import Customer, DiaryEntry, LabTask, Role, RoleMenuPermission, UserProfile
from .permissions import MenuPermission, get_all_menu_levels
from .serializers import (
    ContactAdminSerializer,
    CustomerSerializer,
    DiaryEntrySerializer,
    LabTaskSerializer,
    RoleSerializer,
    UserAdminSerializer,
)

User = get_user_model()


def _sync_user_roles(user, role_ids):
    if role_ids is None:
        return
    profile, _ = UserProfile.objects.get_or_create(user=user)
    profile.roles.set(Role.objects.filter(id__in=role_ids))


def _sync_role_extras(role, data):
    permissions_data = data.get('menu_permissions')
    if permissions_data is not None:
        for item in permissions_data:
            RoleMenuPermission.objects.update_or_create(
                role=role, menu_key=item['menu_key'], defaults={'level': item['level']},
            )

    member_ids = data.get('member_ids')
    if member_ids is not None:
        member_ids = set(member_ids)
        for uid in member_ids:
            profile, _ = UserProfile.objects.get_or_create(user_id=uid)
            profile.roles.add(role)
        for profile in UserProfile.objects.filter(roles=role).exclude(user_id__in=member_ids):
            profile.roles.remove(role)


class LabTokenObtainPairView(TokenObtainPairView):
    """Labログイン。閲覧・操作できるメニューは権限管理の設定に依存する。"""

    def post(self, request, *args, **kwargs):
        username = request.data.get('username', '')
        password = request.data.get('password', '')

        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'detail': 'ユーザー名またはパスワードが正しくありません。'}, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({'detail': 'このアカウントは無効化されています。'}, status=status.HTTP_403_FORBIDDEN)

        if not user.check_password(password):
            return Response({'detail': 'ユーザー名またはパスワードが正しくありません。'}, status=status.HTTP_401_UNAUTHORIZED)

        return super().post(request, *args, **kwargs)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        return Response({
            'username': user.username,
            'email': user.email,
            'is_staff': user.is_staff,
            'is_superuser': user.is_superuser,
            'permissions': get_all_menu_levels(user),
        })


class SetPasswordView(APIView):
    """招待メールのリンクから初回パスワードを設定する（未ログインでも利用可能）"""

    permission_classes = [AllowAny]

    def post(self, request):
        uidb64 = request.data.get('uid', '')
        token = request.data.get('token', '')
        password = request.data.get('password', '')

        if not password or len(password) < 8:
            return Response({'detail': 'パスワードは8文字以上で入力してください。'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            uid = force_str(urlsafe_base64_decode(uidb64))
            user = User.objects.get(pk=uid)
        except (TypeError, ValueError, OverflowError, User.DoesNotExist):
            return Response({'detail': '無効なリンクです。'}, status=status.HTTP_400_BAD_REQUEST)

        if not default_token_generator.check_token(user, token):
            return Response({'detail': 'リンクの有効期限が切れています。'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(password)
        user.is_active = True
        user.save()
        return Response({'detail': 'パスワードを設定しました。'})


class ContactListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'contacts'
    serializer_class = ContactAdminSerializer
    queryset = ContactMessage.objects.all()


class ContactDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'contacts'
    serializer_class = ContactAdminSerializer
    queryset = ContactMessage.objects.all()
    http_method_names = ['get', 'patch', 'head', 'options']


class CustomerListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'customers'
    serializer_class = CustomerSerializer
    queryset = Customer.objects.all()


class CustomerDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'customers'
    serializer_class = CustomerSerializer
    queryset = Customer.objects.all()


class CustomerInviteView(APIView):
    """顧客情報からLabログインアカウントを発行し、招待メールを送信する"""

    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'customers'

    def post(self, request, pk):
        try:
            customer = Customer.objects.get(pk=pk)
        except Customer.DoesNotExist:
            return Response({'detail': '顧客が見つかりません。'}, status=status.HTTP_404_NOT_FOUND)

        if customer.user_id:
            return Response({'detail': 'すでにLabアカウントが発行されています。'}, status=status.HTTP_400_BAD_REQUEST)

        if not customer.email:
            return Response({'detail': 'メールアドレスが未登録のため招待できません。'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=customer.email).exists():
            return Response({'detail': '同じメールアドレスのユーザーが既に存在します。'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create(username=customer.email, email=customer.email, is_active=True)
        user.set_unusable_password()
        user.save()

        customer.user = user
        customer.save(update_fields=['user'])

        send_invite_email(user, intro=f'{customer.name} 様\n\n永井のLabへのログインアカウントが作成されました。')

        return Response(CustomerSerializer(customer).data)


class TaskListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'tasks'
    serializer_class = LabTaskSerializer
    queryset = LabTask.objects.all()


class TaskDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'tasks'
    serializer_class = LabTaskSerializer
    queryset = LabTask.objects.all()


class DiaryListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'diary'
    serializer_class = DiaryEntrySerializer

    def get_queryset(self):
        queryset = DiaryEntry.objects.all()
        year = self.request.query_params.get('year')
        month = self.request.query_params.get('month')
        if year:
            queryset = queryset.filter(date__year=year)
        if month:
            queryset = queryset.filter(date__month=month)
        return queryset


class DiaryDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'diary'
    serializer_class = DiaryEntrySerializer
    queryset = DiaryEntry.objects.all()


class UserListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'users'
    serializer_class = UserAdminSerializer
    queryset = User.objects.all().order_by('-date_joined')

    def perform_create(self, serializer):
        user = serializer.save()
        user.set_unusable_password()
        user.save()
        _sync_user_roles(user, self.request.data.get('role_ids'))
        send_invite_email(user)


class UserDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'users'
    serializer_class = UserAdminSerializer
    queryset = User.objects.all()

    def perform_update(self, serializer):
        user = serializer.save()
        _sync_user_roles(user, self.request.data.get('role_ids'))

    def perform_destroy(self, instance):
        if instance.is_superuser:
            raise ValidationError('スーパーユーザーは削除できません。')
        instance.delete()


class RoleListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'roles'
    serializer_class = RoleSerializer
    queryset = Role.objects.all().prefetch_related('menu_permissions', 'members')

    def perform_create(self, serializer):
        role = serializer.save()
        _sync_role_extras(role, self.request.data)


class RoleDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsAuthenticated, MenuPermission]
    menu_key = 'roles'
    serializer_class = RoleSerializer
    queryset = Role.objects.all().prefetch_related('menu_permissions', 'members')

    def perform_update(self, serializer):
        role = serializer.save()
        _sync_role_extras(role, self.request.data)
