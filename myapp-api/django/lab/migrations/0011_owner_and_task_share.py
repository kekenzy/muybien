import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


def assign_owners(apps, schema_editor):
    User = apps.get_model('auth', 'User')
    owner = User.objects.filter(is_superuser=True).order_by('id').first()
    if owner is None:
        owner = User.objects.order_by('id').first()
    if owner is None:
        return
    for model_name in ('LabTask', 'DiaryEntry', 'Memo', 'DailyItem'):
        Model = apps.get_model('lab', model_name)
        Model.objects.filter(owner__isnull=True).update(owner_id=owner.id)


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('lab', '0010_memophoto'),
    ]

    operations = [
        migrations.AddField(
            model_name='labtask',
            name='is_shared',
            field=models.BooleanField(
                default=False,
                help_text='ONにすると、紐づく親・子・先行/後続タスクも含めて他のLabユーザーに見える',
                verbose_name='共有',
            ),
        ),
        migrations.AddField(
            model_name='labtask',
            name='owner',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='lab_tasks',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AddField(
            model_name='diaryentry',
            name='owner',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='diary_entries',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AddField(
            model_name='memo',
            name='owner',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='memos',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AddField(
            model_name='dailyitem',
            name='owner',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='daily_items',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AlterField(
            model_name='diaryentry',
            name='date',
            field=models.DateField(db_index=True, verbose_name='日付'),
        ),
        migrations.RunPython(assign_owners, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='labtask',
            name='owner',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='lab_tasks',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AlterField(
            model_name='diaryentry',
            name='owner',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='diary_entries',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AlterField(
            model_name='memo',
            name='owner',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='memos',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AlterField(
            model_name='dailyitem',
            name='owner',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='daily_items',
                to=settings.AUTH_USER_MODEL,
                verbose_name='所有者',
            ),
        ),
        migrations.AlterUniqueTogether(
            name='diaryentry',
            unique_together={('owner', 'date')},
        ),
    ]
