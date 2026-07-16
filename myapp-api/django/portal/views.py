import stripe
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date, parse_datetime
from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .availability import compute_available_slots, is_slot_available, slot_duration
from .models import Appointment
from .permissions import IsPortalCustomer
from .serializers import AppointmentSerializer
from .stripe_client import (
    create_setup_intent,
    detach_payment_method,
    list_payment_methods,
    payment_method_belongs_to_customer,
    set_default_payment_method,
)


class PortalAvailabilityView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def get(self, request):
        date_from = parse_date(request.query_params.get('from', '')) or timezone.localdate()
        date_to = parse_date(request.query_params.get('to', '')) or date_from
        if date_to < date_from:
            return Response({'detail': '期間の指定が正しくありません。'}, status=status.HTTP_400_BAD_REQUEST)

        slots = compute_available_slots(date_from, date_to)
        return Response([
            {'start_at': slot['start_at'].isoformat(), 'end_at': slot['end_at'].isoformat()}
            for slot in slots
        ])


class PortalAppointmentListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]
    serializer_class = AppointmentSerializer

    def get_queryset(self):
        return Appointment.objects.filter(customer=self.request.user.customer_profile)

    def create(self, request, *args, **kwargs):
        start_at = parse_datetime(request.data.get('start_at', ''))
        if not start_at:
            return Response({'detail': '日時の形式が正しくありません。'}, status=status.HTTP_400_BAD_REQUEST)
        if timezone.is_naive(start_at):
            start_at = timezone.make_aware(start_at)

        end_at = start_at + slot_duration()
        if not is_slot_available(start_at, end_at):
            return Response({'detail': '指定の時間帯は空いていません。'}, status=status.HTTP_400_BAD_REQUEST)

        appointment = Appointment.objects.create(
            customer=request.user.customer_profile,
            start_at=start_at,
            end_at=end_at,
            note=request.data.get('note', ''),
        )
        return Response(AppointmentSerializer(appointment).data, status=status.HTTP_201_CREATED)


class PortalAppointmentDetailView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def get_object(self, request, pk):
        return get_object_or_404(Appointment, pk=pk, customer=request.user.customer_profile)

    def patch(self, request, pk):
        appointment = self.get_object(request, pk)
        if appointment.status != Appointment.STATUS_CONFIRMED:
            return Response({'detail': 'キャンセル済みの予約は変更できません。'}, status=status.HTTP_400_BAD_REQUEST)
        if appointment.start_at <= timezone.now():
            return Response({'detail': '過去の予約は変更できません。'}, status=status.HTTP_400_BAD_REQUEST)

        start_at = parse_datetime(request.data.get('start_at', ''))
        if not start_at:
            return Response({'detail': '日時の形式が正しくありません。'}, status=status.HTTP_400_BAD_REQUEST)
        if timezone.is_naive(start_at):
            start_at = timezone.make_aware(start_at)

        end_at = start_at + slot_duration()
        if not is_slot_available(start_at, end_at, exclude_appointment_id=appointment.pk):
            return Response({'detail': '指定の時間帯は空いていません。'}, status=status.HTTP_400_BAD_REQUEST)

        appointment.start_at = start_at
        appointment.end_at = end_at
        appointment.save(update_fields=['start_at', 'end_at', 'updated_at'])
        return Response(AppointmentSerializer(appointment).data)

    def delete(self, request, pk):
        appointment = self.get_object(request, pk)
        if appointment.status == Appointment.STATUS_CANCELLED:
            return Response({'detail': 'すでにキャンセル済みです。'}, status=status.HTTP_400_BAD_REQUEST)

        appointment.status = Appointment.STATUS_CANCELLED
        appointment.cancelled_at = timezone.now()
        appointment.save(update_fields=['status', 'cancelled_at', 'updated_at'])
        return Response(status=status.HTTP_204_NO_CONTENT)


class PortalPaymentMethodListView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def get(self, request):
        return Response(list_payment_methods(request.user.customer_profile))


class PortalSetupIntentView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def post(self, request):
        try:
            client_secret = create_setup_intent(request.user.customer_profile)
        except stripe.error.StripeError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response({'client_secret': client_secret})


class PortalPaymentMethodDefaultView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def post(self, request, payment_method_id):
        customer = request.user.customer_profile
        if not payment_method_belongs_to_customer(customer, payment_method_id):
            return Response({'detail': '対象のカードが見つかりません。'}, status=status.HTTP_404_NOT_FOUND)

        try:
            set_default_payment_method(customer, payment_method_id)
        except stripe.error.StripeError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(status=status.HTTP_204_NO_CONTENT)


class PortalPaymentMethodDeleteView(APIView):
    permission_classes = [IsAuthenticated, IsPortalCustomer]

    def delete(self, request, payment_method_id):
        customer = request.user.customer_profile
        if not payment_method_belongs_to_customer(customer, payment_method_id):
            return Response({'detail': '対象のカードが見つかりません。'}, status=status.HTTP_404_NOT_FOUND)

        try:
            detach_payment_method(payment_method_id)
        except stripe.error.StripeError as exc:
            return Response({'detail': str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        return Response(status=status.HTTP_204_NO_CONTENT)
