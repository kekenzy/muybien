from django.contrib import admin

from .models import Appointment, AvailabilityRule, ReservationSettings


@admin.register(AvailabilityRule)
class AvailabilityRuleAdmin(admin.ModelAdmin):
    list_display = ['weekday', 'start_time', 'end_time', 'is_active']
    list_filter = ['weekday', 'is_active']


@admin.register(ReservationSettings)
class ReservationSettingsAdmin(admin.ModelAdmin):
    list_display = ['slot_minutes', 'min_notice_hours', 'max_advance_days']


@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ['customer', 'start_at', 'end_at', 'status', 'created_at']
    list_filter = ['status']
    search_fields = ['customer__name', 'customer__email', 'note']
