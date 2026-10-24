"""Lab 個人データとタスク共有の可視範囲。"""

from django.db.models import QuerySet

from .models import LabTask


def owned_queryset(queryset: QuerySet, user) -> QuerySet:
    return queryset.filter(owner=user)


def visible_tasks_queryset(user) -> QuerySet:
    """自分のタスク + 共有タスクとその親・子・先行/後続の閉包。"""
    owned_ids = set(LabTask.objects.filter(owner=user).values_list('id', flat=True))
    shared_ids = set(LabTask.objects.filter(is_shared=True).values_list('id', flat=True))
    related_ids = _expand_linked_task_ids(shared_ids)
    return LabTask.objects.filter(id__in=owned_ids | related_ids).prefetch_related('dependencies', 'photos')


def _expand_linked_task_ids(seed_ids: set[int]) -> set[int]:
    """親・子・依存関係でつながるタスク ID をすべて集める。"""
    if not seed_ids:
        return set()

    visible = set(seed_ids)
    while True:
        before = len(visible)

        child_ids = set(
            LabTask.objects.filter(parent_id__in=visible).values_list('id', flat=True)
        )
        parent_ids = set(
            LabTask.objects.filter(id__in=visible)
            .exclude(parent_id=None)
            .values_list('parent_id', flat=True)
        )
        dep_from = set(
            LabTask.dependencies.through.objects.filter(from_labtask_id__in=visible)
            .values_list('to_labtask_id', flat=True)
        )
        dep_to = set(
            LabTask.dependencies.through.objects.filter(to_labtask_id__in=visible)
            .values_list('from_labtask_id', flat=True)
        )
        visible |= child_ids | parent_ids | dep_from | dep_to
        if len(visible) == before:
            break

    return visible
