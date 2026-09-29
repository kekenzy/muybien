from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('lab', '0008_diaryphoto'),
    ]

    operations = [
        migrations.CreateModel(
            name='DailyItem',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('title', models.CharField(max_length=100, verbose_name='タイトル')),
                ('color', models.CharField(default='#facc15', max_length=7, verbose_name='色')),
                ('mark', models.CharField(choices=[('star', '★'), ('circle', '●'), ('heart', '♥'), ('diamond', '◆'), ('triangle', '▲'), ('check', '✔')], default='star', max_length=10, verbose_name='印')),
                ('order', models.PositiveIntegerField(default=0, verbose_name='表示順')),
                ('is_active', models.BooleanField(default=True, verbose_name='有効')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='作成日時')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='更新日時')),
            ],
            options={
                'verbose_name': 'Daily項目',
                'verbose_name_plural': 'Daily項目',
                'ordering': ['order', 'id'],
            },
        ),
        migrations.CreateModel(
            name='DailyCheck',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField(db_index=True, verbose_name='日付')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='作成日時')),
                ('item', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='checks', to='lab.dailyitem', verbose_name='項目')),
            ],
            options={
                'verbose_name': 'Dailyチェック',
                'verbose_name_plural': 'Dailyチェック',
                'ordering': ['date', 'item'],
                'unique_together': {('item', 'date')},
            },
        ),
        migrations.AlterField(
            model_name='rolemenupermission',
            name='menu_key',
            field=models.CharField(choices=[('contacts', 'お問い合わせ一覧'), ('customers', '顧客管理'), ('tasks', 'タスク管理'), ('diary', '日記'), ('memo', 'メモ'), ('daily', 'Daily'), ('reservations', '予約管理'), ('users', 'ユーザー管理'), ('roles', '権限管理'), ('announcements', 'お知らせ管理'), ('site_content', 'サイトコンテンツ管理')], max_length=30, verbose_name='メニュー'),
        ),
    ]
