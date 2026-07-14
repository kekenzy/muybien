from rest_framework.permissions import SAFE_METHODS, BasePermission

from .models import MENU_CHOICES, RoleMenuPermission


def get_menu_level(user, menu_key):
    if not user or not user.is_authenticated:
        return RoleMenuPermission.LEVEL_NONE
    if user.is_superuser or user.is_staff:
        return RoleMenuPermission.LEVEL_WRITE
    profile = getattr(user, 'lab_profile', None)
    if not profile:
        return RoleMenuPermission.LEVEL_NONE
    levels = RoleMenuPermission.objects.filter(
        role__in=profile.roles.all(), menu_key=menu_key,
    ).values_list('level', flat=True)
    return max(levels, default=RoleMenuPermission.LEVEL_NONE)


def get_all_menu_levels(user):
    return {key: get_menu_level(user, key) for key, _ in MENU_CHOICES}


class MenuPermission(BasePermission):
    """view.menu_key に対する参照/参照編集権限をチェックする。

    superuser・staff は常にフル権限。それ以外はUserProfileに紐づく
    ロールの中で最も強い権限レベルを採用する。
    """

    def has_permission(self, request, view):
        menu_key = getattr(view, 'menu_key', None)
        if not menu_key:
            return False
        level = get_menu_level(request.user, menu_key)
        if request.method in SAFE_METHODS:
            return level >= RoleMenuPermission.LEVEL_READ
        return level >= RoleMenuPermission.LEVEL_WRITE
