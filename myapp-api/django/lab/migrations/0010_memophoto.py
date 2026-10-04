from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0009_daily'),
    ]

    operations = [
        migrations.CreateModel(
            name='MemoPhoto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('storage_key', models.CharField(max_length=255, verbose_name='保存キー')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='作成日時')),
                ('memo', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='photos', to='lab.memo', verbose_name='メモ')),
            ],
            options={
                'verbose_name': 'メモの写真',
                'verbose_name_plural': 'メモの写真',
                'ordering': ['id'],
            },
        ),
    ]
