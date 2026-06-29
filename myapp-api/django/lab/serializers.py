from contact.models import ContactMessage
from rest_framework import serializers


class ContactAdminSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactMessage
        fields = ['id', 'name', 'email', 'subject', 'message', 'created_at', 'is_replied']
        read_only_fields = ['id', 'name', 'email', 'subject', 'message', 'created_at']
