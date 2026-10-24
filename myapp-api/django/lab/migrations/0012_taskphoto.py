import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0011_owner_and_task_share'),
    ]

    operations = [
        migrations.CreateModel(
            name='TaskPhoto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('storage_key', models.CharField(max_length=255, verbose_name='保存キー')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='作成日時')),
                ('task', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='photos', to='lab.labtask', verbose_name='タスク')),
            ],
            options={
                'verbose_name': 'タスクの写真',
                'verbose_name_plural': 'タスクの写真',
                'ordering': ['id'],
            },
        ),
    ]
