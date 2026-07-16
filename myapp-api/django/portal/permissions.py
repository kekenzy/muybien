from rest_framework.permissions import BasePermission


class IsPortalCustomer(BasePermission):
    """顧客ポータル用の権限チェック。Lab管理者向けのMenuPermissionとは独立している。"""

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and hasattr(user, 'customer_profile'))
