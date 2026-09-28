from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0007_labtask_wbs'),
    ]

    operations = [
        migrations.CreateModel(
            name='DiaryPhoto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('storage_key', models.CharField(max_length=255, verbose_name='保存キー')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='作成日時')),
                ('diary', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='photos', to='lab.diaryentry', verbose_name='日記')),
            ],
            options={
                'verbose_name': '日記の写真',
                'verbose_name_plural': '日記の写真',
                'ordering': ['id'],
            },
        ),
    ]
