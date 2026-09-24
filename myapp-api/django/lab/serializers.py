from contact.models import ContactMessage
from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Customer, DiaryEntry, LabTask, Memo, Role, RoleMenuPermission

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
        fields = [
            'id', 'title', 'description', 'status', 'priority', 'start_date', 'due_date',
            'duration_days', 'progress', 'parent', 'order', 'dependencies', 'created_at', 'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
        extra_kwargs = {'dependencies': {'required': False}}

    def validate(self, attrs):
        start = attrs.get('start_date', getattr(self.instance, 'start_date', None))
        due = attrs.get('due_date', getattr(self.instance, 'due_date', None))
        if start and due and due < start:
            raise serializers.ValidationError({'due_date': '終了日は開始日以降にしてください。'})

        if self.instance:
            # 自分自身や子孫を親にすると循環するので弾く
            node = attrs.get('parent')
            while node:
                if node.pk == self.instance.pk:
                    raise serializers.ValidationError({'parent': '自分自身や子タスクを親にはできません。'})
                node = node.parent
            if any(dep.pk == self.instance.pk for dep in attrs.get('dependencies', [])):
                raise serializers.ValidationError({'dependencies': '自分自身を先行タスクにはできません。'})
        return attrs


class DiaryEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DiaryEntry
        fields = ['id', 'date', 'title', 'content', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class MemoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Memo
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
