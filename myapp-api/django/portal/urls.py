from django.urls import path

from .views import (
    PortalAppointmentDetailView,
    PortalAppointmentListCreateView,
    PortalAvailabilityView,
    PortalPaymentMethodDefaultView,
    PortalPaymentMethodDeleteView,
    PortalPaymentMethodListView,
    PortalSetupIntentView,
)

urlpatterns = [
    path('portal/availability', PortalAvailabilityView.as_view()),
    path('portal/appointments', PortalAppointmentListCreateView.as_view()),
    path('portal/appointments/<int:pk>', PortalAppointmentDetailView.as_view()),
    path('portal/payment-methods', PortalPaymentMethodListView.as_view()),
    path('portal/payment-methods/setup-intent', PortalSetupIntentView.as_view()),
    path('portal/payment-methods/<str:payment_method_id>/default', PortalPaymentMethodDefaultView.as_view()),
    path('portal/payment-methods/<str:payment_method_id>', PortalPaymentMethodDeleteView.as_view()),
]
