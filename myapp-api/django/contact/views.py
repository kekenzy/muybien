import logging
from django.conf import settings
from django.core.mail import send_mail
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import ContactMessage
from .serializers import ContactMessageSerializer

logger = logging.getLogger('contact')


class ContactView(APIView):
    def post(self, request):
        serializer = ContactMessageSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        contact = serializer.save()

        try:
            send_mail(
                subject=f'[MuyBien] お問い合わせ: {contact.subject}',
                message=(
                    f'お名前: {contact.name}\n'
                    f'メール: {contact.email}\n'
                    f'件名: {contact.subject}\n\n'
                    f'メッセージ:\n{contact.message}'
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[settings.CONTACT_NOTIFY_EMAIL],
                fail_silently=False,
            )
        except Exception as e:
            logger.error(f'Contact email failed: {e}')

        return Response({'message': 'お問い合わせを受け付けました。'}, status=status.HTTP_201_CREATED)
