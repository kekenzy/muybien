import logging
from django.conf import settings
from django.core.mail import EmailMessage, send_mail
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
            admin_mail = EmailMessage(
                subject=f'[MuyBien] お問い合わせ: {contact.subject}',
                body=(
                    f'お名前: {contact.name}\n'
                    f'メール: {contact.email}\n'
                    f'件名: {contact.subject}\n\n'
                    f'メッセージ:\n{contact.message}'
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[settings.CONTACT_NOTIFY_EMAIL],
                reply_to=[contact.email],
            )
            admin_mail.send(fail_silently=False)

            send_mail(
                subject='【MuyBien】お問い合わせを受け付けました',
                message=(
                    f'{contact.name} 様\n\n'
                    f'この度はお問い合わせいただきありがとうございます。\n'
                    f'以下の内容で受け付けました。\n'
                    f'通常1〜2営業日以内にご返信いたします。\n\n'
                    f'---\n'
                    f'件名: {contact.subject}\n\n'
                    f'{contact.message}\n'
                    f'---\n\n'
                    f'MuyBien\n'
                    f'https://muybien.jp/'
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[contact.email],
                fail_silently=False,
            )
        except Exception as e:
            logger.error(f'Contact email failed: {e}')

        return Response({'message': 'お問い合わせを受け付けました。'}, status=status.HTTP_201_CREATED)
