from django.db import models

from lab.models import Customer

WEEKDAY_CHOICES = [
    (0, '月'), (1, '火'), (2, '水'), (3, '木'), (4, '金'), (5, '土'), (6, '日'),
]


class AvailabilityRule(models.Model):
    weekday = models.PositiveSmallIntegerField('曜日', choices=WEEKDAY_CHOICES)
    start_time = models.TimeField('開始時刻')
    end_time = models.TimeField('終了時刻')
    is_active = models.BooleanField('有効', default=True)

    class Meta:
        verbose_name = '営業時間'
        verbose_name_plural = '営業時間一覧'
        ordering = ['weekday', 'start_time']

    def __str__(self):
        return f'{self.get_weekday_display()} {self.start_time}-{self.end_time}'


class ReservationSettings(models.Model):
    slot_minutes = models.PositiveSmallIntegerField('予約単位(分)', default=60)
    min_notice_hours = models.PositiveIntegerField('最短予約受付(時間前)', default=24)
    max_advance_days = models.PositiveIntegerField('予約可能日数(何日先まで)', default=60)

    class Meta:
        verbose_name = '予約設定'
        verbose_name_plural = '予約設定'

    def __str__(self):
        return '予約設定'

    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)
        return obj


class Appointment(models.Model):
    STATUS_CONFIRMED = 'confirmed'
    STATUS_CANCELLED = 'cancelled'
    STATUS_CHOICES = [(STATUS_CONFIRMED, '確定'), (STATUS_CANCELLED, 'キャンセル')]

    customer = models.ForeignKey(
        Customer, verbose_name='顧客', on_delete=models.CASCADE, related_name='appointments',
    )
    start_at = models.DateTimeField('開始日時')
    end_at = models.DateTimeField('終了日時')
    status = models.CharField('ステータス', max_length=20, choices=STATUS_CHOICES, default=STATUS_CONFIRMED)
    note = models.TextField('備考', blank=True)
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)
    cancelled_at = models.DateTimeField('キャンセル日時', null=True, blank=True)

    class Meta:
        verbose_name = '予約'
        verbose_name_plural = '予約一覧'
        ordering = ['start_at']

    def __str__(self):
        return f'{self.customer.name} {self.start_at}'
