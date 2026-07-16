from datetime import datetime, timedelta

from django.utils import timezone

from .models import Appointment, AvailabilityRule, ReservationSettings


def _slots_overlap(start, end, busy_ranges):
    return any(start < busy_end and end > busy_start for busy_start, busy_end in busy_ranges)


def compute_available_slots(date_from, date_to):
    """指定期間内の空き枠を [{'start_at': datetime, 'end_at': datetime}, ...] で返す"""
    settings_obj = ReservationSettings.load()
    slot_duration = timedelta(minutes=settings_obj.slot_minutes)
    now = timezone.localtime()
    earliest_start = now + timedelta(hours=settings_obj.min_notice_hours)
    latest_date = now.date() + timedelta(days=settings_obj.max_advance_days)

    date_to = min(date_to, latest_date)
    if date_from > date_to:
        return []

    rules_by_weekday = {}
    for rule in AvailabilityRule.objects.filter(is_active=True):
        rules_by_weekday.setdefault(rule.weekday, []).append(rule)

    busy_ranges = list(
        Appointment.objects.filter(
            status=Appointment.STATUS_CONFIRMED,
            start_at__date__gte=date_from,
            start_at__date__lte=date_to,
        ).values_list('start_at', 'end_at')
    )

    tz = timezone.get_current_timezone()
    slots = []
    current_date = date_from
    while current_date <= date_to:
        for rule in rules_by_weekday.get(current_date.weekday(), []):
            slot_start = timezone.make_aware(datetime.combine(current_date, rule.start_time), tz)
            day_end = timezone.make_aware(datetime.combine(current_date, rule.end_time), tz)
            while slot_start + slot_duration <= day_end:
                slot_end = slot_start + slot_duration
                if slot_start >= earliest_start and not _slots_overlap(slot_start, slot_end, busy_ranges):
                    slots.append({'start_at': slot_start, 'end_at': slot_end})
                slot_start = slot_end
        current_date += timedelta(days=1)
    return slots


def slot_duration():
    return timedelta(minutes=ReservationSettings.load().slot_minutes)


def is_slot_available(start_at, end_at, exclude_appointment_id=None):
    settings_obj = ReservationSettings.load()
    now = timezone.localtime()
    earliest_start = now + timedelta(hours=settings_obj.min_notice_hours)
    if start_at < earliest_start:
        return False

    rule_exists = AvailabilityRule.objects.filter(
        is_active=True,
        weekday=start_at.weekday(),
        start_time__lte=start_at.time(),
        end_time__gte=end_at.time(),
    ).exists()
    if not rule_exists:
        return False

    conflicts = Appointment.objects.filter(
        status=Appointment.STATUS_CONFIRMED, start_at__lt=end_at, end_at__gt=start_at,
    )
    if exclude_appointment_id:
        conflicts = conflicts.exclude(pk=exclude_appointment_id)
    return not conflicts.exists()
