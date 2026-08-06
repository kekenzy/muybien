from django.db import models

# 公開サイトの「繰り返しリスト」セクション一覧。新しいセクションを追加する場合はここに追加する。
SECTION_CHOICES = [
    ('home_stats', 'ホーム: 実績数値'),
    ('home_skills', 'ホーム: 技術スタック'),
    ('services', 'サービス一覧'),
    ('portfolio', '実績・ポートフォリオ'),
    ('profile_values', 'プロフィール: こんな人です'),
    ('profile_career', 'プロフィール: キャリア'),
    ('profile_apps', 'プロフィール: 作成物'),
    ('profile_skills', 'プロフィール: 技術スタック'),
]


class Announcement(models.Model):
    title = models.CharField('タイトル', max_length=200)
    body = models.TextField('本文')
    cover_image = models.ImageField('アイキャッチ画像', upload_to='announcements/', null=True, blank=True)
    is_published = models.BooleanField('公開', default=False)
    published_at = models.DateTimeField('公開日時', null=True, blank=True)
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = 'お知らせ'
        verbose_name_plural = 'お知らせ一覧'
        ordering = ['-published_at', '-created_at']

    def __str__(self):
        return self.title


class SiteText(models.Model):
    """トップページ等の見出し・導入文・CTA文言など、単一テキスト項目を保持する"""

    key = models.CharField('キー', max_length=100, unique=True)
    value = models.TextField('値', blank=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = 'サイトテキスト'
        verbose_name_plural = 'サイトテキスト一覧'
        ordering = ['key']

    def __str__(self):
        return self.key


class ContentItem(models.Model):
    """Home統計/スキル・Services・Portfolio・Profileの各繰り返しリストを1モデルで表現する。

    項目ごとの具体的なフィールドは`data`(JSON)に持たせ、`section`で区別する。
    """

    section = models.CharField('セクション', max_length=30, choices=SECTION_CHOICES)
    order = models.PositiveIntegerField('表示順', default=0)
    is_active = models.BooleanField('表示', default=True)
    image = models.ImageField('画像', upload_to='content_items/', null=True, blank=True)
    image_secondary = models.ImageField('画像2', upload_to='content_items/', null=True, blank=True)
    data = models.JSONField('データ', default=dict, blank=True)
    created_at = models.DateTimeField('作成日時', auto_now_add=True)
    updated_at = models.DateTimeField('更新日時', auto_now=True)

    class Meta:
        verbose_name = 'コンテンツ項目'
        verbose_name_plural = 'コンテンツ項目一覧'
        ordering = ['section', 'order', 'id']

    def __str__(self):
        return f'{self.get_section_display()} #{self.order}'
