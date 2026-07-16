from rest_framework import serializers

from .models import Appointment, AvailabilityRule, ReservationSettings


class AvailabilityRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = AvailabilityRule
        fields = ['id', 'weekday', 'start_time', 'end_time', 'is_active']
        read_only_fields = ['id']


class ReservationSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = ReservationSettings
        fields = ['slot_minutes', 'min_notice_hours', 'max_advance_days']


class AppointmentSerializer(serializers.ModelSerializer):
    """顧客ポータル向け。customerは自分自身に固定されるためread-only。"""

    class Meta:
        model = Appointment
        fields = ['id', 'start_at', 'end_at', 'status', 'note', 'created_at', 'updated_at', 'cancelled_at']
        read_only_fields = ['id', 'end_at', 'status', 'created_at', 'updated_at', 'cancelled_at']


class AppointmentAdminSerializer(serializers.ModelSerializer):
    """Lab管理者向け。顧客名を含めて返す。"""

    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_email = serializers.CharField(source='customer.email', read_only=True)

    class Meta:
        model = Appointment
        fields = [
            'id', 'customer', 'customer_name', 'customer_email', 'start_at', 'end_at',
            'status', 'note', 'created_at', 'updated_at', 'cancelled_at',
        ]
        read_only_fields = [
            'id', 'customer', 'customer_name', 'customer_email', 'start_at', 'end_at',
            'created_at', 'updated_at', 'cancelled_at',
        ]
