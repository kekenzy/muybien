from django.contrib import admin

from .models import Customer, DiaryEntry, LabTask, Role, RoleMenuPermission, UserProfile


@admin.register(LabTask)
class LabTaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'status', 'priority', 'start_date', 'due_date', 'progress', 'parent']
    list_filter = ['status', 'priority']
    search_fields = ['title', 'description']


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = ['name', 'email', 'phone', 'company', 'user', 'created_at']
    search_fields = ['name', 'email', 'phone', 'company', 'memo']


class RoleMenuPermissionInline(admin.TabularInline):
    model = RoleMenuPermission
    extra = 0


@admin.register(Role)
class RoleAdmin(admin.ModelAdmin):
    list_display = ['name', 'created_at']
    search_fields = ['name']
    inlines = [RoleMenuPermissionInline]


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user']
    filter_horizontal = ['roles']


@admin.register(DiaryEntry)
class DiaryEntryAdmin(admin.ModelAdmin):
    list_display = ['date', 'title', 'created_at']
    search_fields = ['title', 'content']
