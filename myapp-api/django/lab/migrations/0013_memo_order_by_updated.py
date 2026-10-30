from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0012_taskphoto'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='memo',
            options={
                'ordering': ['-updated_at', '-id'],
                'verbose_name': 'メモ',
                'verbose_name_plural': 'メモ',
            },
        ),
    ]
