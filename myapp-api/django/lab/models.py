from django.conf import settings
from django.db import models

# 権限管理の対象メニュー一覧。新しいLabメニューを追加する場合はここにも追加すること。
MENU_CHOICES = [
    ('contacts', 'お問い合わせ一覧'),
    ('customers', '顧客管理'),
    ('tasks', 'タスク一覧'),
    ('diary', '日記'),
    ('users', 'ユーザー管理'),
    ('roles', '権限管理'),
]


class Role(models.Model):
    name = models.CharField('ロール名', max_length=100, unique=True)
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = 'ロール'
        verbose_name_plural = 'ロール一覧'
        ordering = ['name']

    def __str__(self):
        return self.name


class RoleMenuPermission(models.Model):
    LEVEL_NONE = 0
    LEVEL_READ = 1
    LEVEL_WRITE = 2
    LEVEL_CHOICES = [
        (LEVEL_NONE, '権限なし'),
        (LEVEL_READ, '参照'),
        (LEVEL_WRITE, '参照・編集'),
    ]

    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='menu_permissions')
    menu_key = models.CharField('メニュー', max_length=30, choices=MENU_CHOICES)
    level = models.PositiveSmallIntegerField('権限レベル', choices=LEVEL_CHOICES, default=LEVEL_NONE)

    class Meta:
        verbose_name = 'ロールメニュー権限'
        verbose_name_plural = 'ロールメニュー権限一覧'
        unique_together = ('role', 'menu_key')

    def __str__(self):
        return f'{self.role.name} / {self.get_menu_key_display()} / {self.get_level_display()}'


class UserProfile(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='lab_profile',
    )
    roles = models.ManyToManyField(Role, verbose_name='ロール', blank=True, related_name='members')

    class Meta:
        verbose_name = 'Labユーザープロフィール'
        verbose_name_plural = 'Labユーザープロフィール一覧'

    def __str__(self):
        return self.user.username


class LabTask(models.Model):
    STATUS_CHOICES = [
        ('todo', '未着手'),
        ('in_progress', '進行中'),
        ('done', '完了'),
    ]

    title = models.CharField('タイトル', max_length=200)
    description = models.TextField('詳細', blank=True)
    status = models.CharField('ステータス', max_length=20, choices=STATUS_CHOICES, default='todo')
    due_date = models.DateField('期限', null=True, blank=True)
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = 'タスク'
        verbose_name_plural = 'タスク一覧'
        ordering = ['due_date', '-created_at']

    def __str__(self):
        return self.title


class Customer(models.Model):
    name = models.CharField('氏名', max_length=100)
    email = models.EmailField('メールアドレス')
    phone = models.CharField('電話番号', max_length=30, blank=True)
    company = models.CharField('会社名', max_length=200, blank=True)
    memo = models.TextField('メモ', blank=True)
    source_contact = models.OneToOneField(
        'contact.ContactMessage',
        verbose_name='元のお問い合わせ',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='customer',
    )
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        verbose_name='Labログインアカウント',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='customer_profile',
    )
    created_at = models.DateTimeField('登録日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = '顧客'
        verbose_name_plural = '顧客一覧'
        ordering = ['-created_at']

    def __str__(self):
        return self.name


class DiaryEntry(models.Model):
    date = models.DateField('日付', unique=True)
    title = models.CharField('タイトル', max_length=200, blank=True)
    content = models.TextField('本文')
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = '日記'
        verbose_name_plural = '日記'
        ordering = ['-date']

    def __str__(self):
        return f'{self.date}'
