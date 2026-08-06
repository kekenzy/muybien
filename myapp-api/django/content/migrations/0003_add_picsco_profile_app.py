from django.db import migrations

PICSCO_DATA = {
    'category': '少年野球アプリ',
    'date': '2026年',
    'title': 'ピクスコ for ベースボール',
    'desc': '少年野球のスコア記録を、家族みんなで共有するWebアプリ。紙のスコアブックとバラバラの写真から、チームで見返せる記録へ。',
    'tags': ['Flutter', 'Firebase', 'スコアブック', '個人開発'],
    'url': '/picsco/index.html',
    'icon_url': '/picsco/favicon.png',
    'screenshot_url': '/picsco/lp_images/hero-youth-game.jpg',
}


def add_picsco(apps, schema_editor):
    SiteText = apps.get_model('content', 'SiteText')
    ContentItem = apps.get_model('content', 'ContentItem')

    SiteText.objects.update_or_create(
        key='profile_apps_heading',
        defaults={'value': '作成物'},
    )

    existing = ContentItem.objects.filter(section='profile_apps')
    if existing.filter(data__title=PICSCO_DATA['title']).exists():
        return
    max_order = existing.order_by('-order').values_list('order', flat=True).first()
    order = (max_order + 1) if max_order is not None else 0
    ContentItem.objects.create(section='profile_apps', order=order, data=PICSCO_DATA)


def remove_picsco(apps, schema_editor):
    ContentItem = apps.get_model('content', 'ContentItem')
    ContentItem.objects.filter(section='profile_apps', data__title=PICSCO_DATA['title']).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('content', '0002_seed_initial_content'),
    ]

    operations = [
        migrations.RunPython(add_picsco, remove_picsco),
    ]
