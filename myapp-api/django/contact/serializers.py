from rest_framework import serializers
from .models import ContactMessage


class ContactMessageSerializer(serializers.ModelSerializer):
    # プライバシーポリシーへの同意。チェックを外したリクエストを直接送られても受け付けない
    agree_privacy = serializers.BooleanField(write_only=True)

    class Meta:
        model = ContactMessage
        fields = ['name', 'email', 'subject', 'message', 'agree_privacy']

    def validate_agree_privacy(self, value):
        if value is not True:
            raise serializers.ValidationError('プライバシーポリシーへの同意が必要です。')
        return value

    def create(self, validated_data):
        validated_data.pop('agree_privacy', None)
        return super().create(validated_data)
