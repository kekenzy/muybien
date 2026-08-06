from django.db import migrations


def fix_picsco_url(apps, schema_editor):
    ContentItem = apps.get_model('content', 'ContentItem')
    for item in ContentItem.objects.filter(section='profile_apps', data__title='ピクスコ for ベースボール'):
        data = dict(item.data)
        if data.get('url') in ('/picsco/', '/picsco'):
            data['url'] = '/picsco/index.html'
            item.data = data
            item.save(update_fields=['data'])


def revert_picsco_url(apps, schema_editor):
    ContentItem = apps.get_model('content', 'ContentItem')
    for item in ContentItem.objects.filter(section='profile_apps', data__title='ピクスコ for ベースボール'):
        data = dict(item.data)
        if data.get('url') == '/picsco/index.html':
            data['url'] = '/picsco/'
            item.data = data
            item.save(update_fields=['data'])


class Migration(migrations.Migration):

    dependencies = [
        ('content', '0003_add_picsco_profile_app'),
    ]

    operations = [
        migrations.RunPython(fix_picsco_url, revert_picsco_url),
    ]
