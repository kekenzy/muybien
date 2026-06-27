from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = []

    operations = [
        migrations.CreateModel(
            name='ContactMessage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100, verbose_name='お名前')),
                ('email', models.EmailField(max_length=254, verbose_name='メールアドレス')),
                ('subject', models.CharField(max_length=200, verbose_name='件名')),
                ('message', models.TextField(verbose_name='メッセージ')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='受信日時')),
                ('is_replied', models.BooleanField(default=False, verbose_name='返信済み')),
            ],
            options={
                'verbose_name': 'お問い合わせ',
                'verbose_name_plural': 'お問い合わせ一覧',
                'ordering': ['-created_at'],
            },
        ),
    ]
