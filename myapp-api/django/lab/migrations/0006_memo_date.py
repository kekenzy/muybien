from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0005_memo_alter_rolemenupermission_menu_key'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='memo',
            options={
                'ordering': ['-date', '-created_at'],
                'verbose_name': 'メモ',
                'verbose_name_plural': 'メモ',
            },
        ),
        migrations.AddField(
            model_name='memo',
            name='date',
            field=models.DateField(blank=True, db_index=True, null=True, verbose_name='日付'),
        ),
    ]
