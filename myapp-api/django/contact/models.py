from django.db import models


class ContactMessage(models.Model):
    name = models.CharField('お名前', max_length=100)
    email = models.EmailField('メールアドレス')
    subject = models.CharField('件名', max_length=200)
    message = models.TextField('メッセージ')
    created_at = models.DateTimeField('受信日時', auto_now_add=True)
    is_replied = models.BooleanField('返信済み', default=False)

    class Meta:
        verbose_name = 'お問い合わせ'
        verbose_name_plural = 'お問い合わせ一覧'
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.name} ({self.email}) - {self.subject}'
