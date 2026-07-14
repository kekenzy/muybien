from contact.models import ContactMessage
from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Customer, DiaryEntry, LabTask, Role, RoleMenuPermission

User = get_user_model()


class ContactAdminSerializer(serializers.ModelSerializer):
    customer_id = serializers.SerializerMethodField()

    class Meta:
        model = ContactMessage
        fields = ['id', 'name', 'email', 'subject', 'message', 'created_at', 'is_replied', 'customer_id']
        read_only_fields = ['id', 'name', 'email', 'subject', 'message', 'created_at', 'customer_id']

    def get_customer_id(self, obj):
        customer = getattr(obj, 'customer', None)
        return customer.id if customer else None


class CustomerSerializer(serializers.ModelSerializer):
    has_login = serializers.SerializerMethodField()

    class Meta:
        model = Customer
        fields = [
            'id', 'name', 'email', 'phone', 'company', 'memo',
            'source_contact', 'has_login', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'has_login', 'created_at', 'updated_at']

    def get_has_login(self, obj):
        return obj.user_id is not None


class LabTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = LabTask
        fields = ['id', 'title', 'description', 'status', 'due_date', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class DiaryEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DiaryEntry
        fields = ['id', 'date', 'title', 'content', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserAdminSerializer(serializers.ModelSerializer):
    role_ids = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'is_active', 'is_staff', 'is_superuser',
            'role_ids', 'date_joined', 'last_login',
        ]
        read_only_fields = ['id', 'is_superuser', 'date_joined', 'last_login']

    def get_role_ids(self, obj):
        profile = getattr(obj, 'lab_profile', None)
        if not profile:
            return []
        return list(profile.roles.values_list('id', flat=True))


class RoleMenuPermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RoleMenuPermission
        fields = ['menu_key', 'level']


class RoleSerializer(serializers.ModelSerializer):
    # 書き込みはビュー側でrequest.dataから直接同期する（読み取り専用として公開）
    menu_permissions = RoleMenuPermissionSerializer(many=True, read_only=True)
    member_ids = serializers.SerializerMethodField()

    class Meta:
        model = Role
        fields = ['id', 'name', 'menu_permissions', 'member_ids', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_member_ids(self, obj):
        return list(obj.members.values_list('user_id', flat=True))
