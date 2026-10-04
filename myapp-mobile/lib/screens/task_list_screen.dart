import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import 'task_edit_screen.dart';

enum _ViewMode { todo, wbs }

/// タスク管理。ToDo はステータス別、WBS は親子の階層で同じタスクを表示する（ガントチャートは Web のみ）。
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task>? _tasks;
  String? _error;
  _ViewMode _mode = _ViewMode.todo;
  bool _showClosed = false;
  Task? _dragging;
  _WbsDrop? _wbsDrop;
  final Set<int> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await ApiClient.instance.listTasks();
      setState(() => _tasks = results.map(Task.fromJson).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openEditor({Task? task, int? parentId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task, initialParentId: parentId)),
    );
    if (changed == true) _load();
  }

  Future<void> _moveStatus(Task task, TaskStatus status) async {
    if (task.status == status) return;
    try {
      await ApiClient.instance.updateTask(
        task.id,
        status == TaskStatus.done
            ? {'status': status.apiValue, 'progress': 100}
            : {'status': status.apiValue},
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _toggleDone(Task task) async {
    final done = task.status == TaskStatus.done;
    try {
      // Web のカンバンと同じく、完了にしたら進捗も100%にする
      await ApiClient.instance.updateTask(
        task.id,
        done ? {'status': TaskStatus.todo.apiValue} : {'status': TaskStatus.done.apiValue, 'progress': 100},
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return Colors.green.shade600;
      case TaskStatus.inProgress:
        return Colors.blue.shade600;
      case TaskStatus.review:
        return Colors.purple.shade400;
      case TaskStatus.onHold:
        return Colors.orange.shade600;
      case TaskStatus.cancelled:
        return Colors.red.shade400;
      case TaskStatus.todo:
        return Colors.grey.shade600;
    }
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red.shade400;
      case TaskPriority.high:
        return Colors.orange.shade600;
      case TaskPriority.medium:
        return Colors.grey.shade600;
      case TaskPriority.low:
        return Colors.grey.shade400;
    }
  }

  String _shortDate(DateTime d) => '${d.month}/${d.day}';

  bool _isOverdue(Task task) {
    final due = task.dueDate;
    if (due == null || task.isClosed) return false;
    final now = DateTime.now();
    return due.isBefore(DateTime(now.year, now.month, now.day));
  }

  // 優先度の高い順 → 期限の近い順（未設定は最後） → 登録順
  int _compareTasks(Task a, Task b) {
    final rank = b.priority.rank.compareTo(a.priority.rank);
    if (rank != 0) return rank;
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad != null && bd != null && ad != bd) return ad.compareTo(bd);
    if (ad == null && bd != null) return 1;
    if (ad != null && bd == null) return -1;
    return a.id.compareTo(b.id);
  }

  List<Task> get _visibleTasks => (_tasks ?? const <Task>[]).where((t) => _showClosed || !t.isClosed).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('タスク管理'),
        actions: [
          const Text('完了', style: TextStyle(fontSize: 12)),
          Checkbox(
            value: _showClosed,
            onChanged: (value) => setState(() => _showClosed = value ?? false),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_ViewMode>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: _ViewMode.todo, label: Text('ToDo'), icon: Icon(Icons.checklist, size: 16)),
                  ButtonSegment(value: _ViewMode.wbs, label: Text('WBS'), icon: Icon(Icons.account_tree_outlined, size: 16)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'task_fab', // 下タブは IndexedStack で同時に存在するのでタグを分ける
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _message(String text) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_error != null) return _message(_error!);
    if (_tasks == null) return const Center(child: CircularProgressIndicator());
    final tasks = _visibleTasks;
    if (tasks.isEmpty) return _message('タスクはまだありません。＋ボタンで追加できます。');
    return _mode == _ViewMode.todo ? _buildTodo(tasks) : _buildWbs(tasks);
  }

  // ---- ToDo（ステータス別） ----

  bool _statusVisible(TaskStatus status) {
    if (_showClosed || _dragging != null) return true;
    return status != TaskStatus.done && status != TaskStatus.cancelled;
  }

  Widget _buildTodo(List<Task> tasks) {
    final titleById = {for (final t in _tasks!) t.id: t.title};
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
      children: [
        for (final status in TaskStatus.values)
          if (_statusVisible(status)) _buildStatusDrop(status, tasks, titleById),
      ],
    );
  }

  Widget _buildStatusDrop(TaskStatus status, List<Task> tasks, Map<int, String> titleById) {
    final group = tasks.where((t) => t.status == status).toList()..sort(_compareTasks);
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => _moveStatus(details.data, status),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(0, 10, 0, 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: hovering ? _statusColor(status).withValues(alpha: 0.15) : null,
                borderRadius: BorderRadius.circular(8),
                border: hovering ? Border.all(color: _statusColor(status)) : null,
              ),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(status.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('${group.length}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  if (hovering) ...[
                    const Spacer(),
                    Text('ここに移動', style: TextStyle(fontSize: 11, color: _statusColor(status))),
                  ],
                ],
              ),
            ),
            for (final task in group)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildTodoCard(task, task.parentId != null ? titleById[task.parentId] : null),
              ),
            if (group.isEmpty)
              const SizedBox(height: 28),
          ],
        );
      },
    );
  }

  Widget _card({required VoidCallback onTap, required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: child),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildTodoCard(Task task, String? parentTitle) {
    final done = task.status == TaskStatus.done;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final card = _card(
      onTap: () => _openEditor(task: task),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Checkbox(value: done, onChanged: (_) => _toggleDone(task)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _badge(task.priority.label, _priorityColor(task.priority)),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.event, size: 12, color: _isOverdue(task) ? Colors.red.shade400 : muted),
                        const SizedBox(width: 2),
                        Text(
                          _shortDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: _isOverdue(task) ? Colors.red.shade400 : muted,
                            fontWeight: _isOverdue(task) ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                      if (task.progress > 0) ...[
                        const SizedBox(width: 6),
                        Text('${task.progress}%', style: TextStyle(fontSize: 11, color: muted)),
                      ],
                      if (parentTitle != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('↳ $parentTitle',
                              style: TextStyle(fontSize: 11, color: muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.title.isEmpty ? '(無題)' : task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? muted : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
    return LongPressDraggable<Task>(
      data: task,
      onDragStarted: () => setState(() => _dragging = task),
      onDragEnd: (_) => setState(() => _dragging = null),
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: card,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }

  // ---- WBS（階層） ----

  Widget _buildWbs(List<Task> tasks) {
    final rows = buildTaskRows(tasks, collapsed: _collapsed);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => _buildWbsRow(rows[index], tasks),
    );
  }

  /// 落とした行と同じ親の並びへ入れる。上半分ならその前、下半分ならその後ろ。
  Future<void> _reorderWbs(int draggedId, int targetId, bool after) async {
    final tasks = _visibleTasks;
    if (draggedId == targetId || descendantIds(tasks, draggedId).contains(targetId)) return;
    final draggedIndex = tasks.indexWhere((t) => t.id == draggedId);
    final targetIndex = tasks.indexWhere((t) => t.id == targetId);
    if (draggedIndex < 0 || targetIndex < 0) return;
    final target = tasks[targetIndex];

    final parentId = target.parentId;
    final siblings = tasks.where((t) => t.parentId == parentId && t.id != draggedId).toList()
      ..sort((a, b) => a.order != b.order ? a.order.compareTo(b.order) : a.id.compareTo(b.id));
    var index = siblings.indexWhere((t) => t.id == target.id);
    if (index < 0) return;
    if (after) index += 1;
    final orderedIds = siblings.map((t) => t.id).toList()..insert(index, draggedId);

    final previous = _tasks;
    setState(() {
      _tasks = [
        for (final task in _tasks!)
          () {
            final place = orderedIds.indexOf(task.id);
            if (place < 0) return task;
            return task.copyWith(
              order: place + 1,
              parentId: task.id == draggedId ? parentId : task.parentId,
              updateParent: task.id == draggedId,
            );
          }(),
      ];
    });

    try {
      final updates = <Future<void>>[];
      for (var i = 0; i < orderedIds.length; i++) {
        final original = tasks.firstWhere((t) => t.id == orderedIds[i]);
        final fields = <String, dynamic>{};
        if (original.order != i + 1) fields['order'] = i + 1;
        if (orderedIds[i] == draggedId && original.parentId != parentId) fields['parent'] = parentId;
        if (fields.isEmpty) continue;
        updates.add(ApiClient.instance.updateTask(orderedIds[i], fields));
      }
      await Future.wait(updates);
    } catch (e) {
      if (mounted) {
        setState(() => _tasks = previous);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('並べ替えに失敗しました: $e')));
      }
    }
  }

  String _periodLabel(Task task) {
    final start = task.startDate;
    final due = task.dueDate;
    if (start == null && due == null) return '日付未設定';
    final range = '${start != null ? _shortDate(start) : ''}〜${due != null ? _shortDate(due) : ''}';
    if (start == null || due == null || due.isBefore(start)) return range;
    final days = task.durationDays ?? countWorkingDays(start, due).toDouble();
    final daysLabel = days == days.roundToDouble() ? days.toInt().toString() : days.toString();
    return '$range（$daysLabel日）';
  }

  Widget _buildWbsRow(TaskRow row, List<Task> tasks) {
    final task = row.task;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final done = task.status == TaskStatus.done;
    final drop = _wbsDrop;
    final highlighted = drop?.id == task.id;
    return _WbsDragRow(
      taskId: task.id,
      title: task.title.isEmpty ? '(無題)' : task.title,
      tasks: tasks,
      highlighted: highlighted,
      dropAfter: highlighted && drop!.after,
      onDragStarted: () => setState(() => _wbsDrop = null),
      onDragEnded: () => setState(() => _wbsDrop = null),
      onHover: (after) {
        final current = _wbsDrop;
        if (current != null && current.id == task.id && current.after == after) return;
        setState(() => _wbsDrop = _WbsDrop(task.id, after));
      },
      onDrop: _reorderWbs,
      child: Padding(
      padding: EdgeInsets.only(left: row.level * 14.0),
      child: _card(
        onTap: () => _openEditor(task: task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 4, 6),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: row.hasChildren
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        icon: Icon(_collapsed.contains(task.id) ? Icons.chevron_right : Icons.expand_more),
                        onPressed: () => setState(() {
                          if (!_collapsed.remove(task.id)) _collapsed.add(task.id);
                        }),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(row.wbsNo, style: TextStyle(fontSize: 11, color: muted, fontFeatures: const [FontFeature.tabularFigures()])),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            task.title.isEmpty ? '(無題)' : task.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: row.hasChildren ? FontWeight.w700 : FontWeight.w600,
                              decoration: done ? TextDecoration.lineThrough : null,
                              color: done ? muted : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(color: _statusColor(task.status), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(task.status.label, style: TextStyle(fontSize: 10, color: muted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _periodLabel(task),
                            style: TextStyle(fontSize: 10, color: _isOverdue(task) ? Colors.red.shade400 : muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('${task.progress}%', style: TextStyle(fontSize: 10, color: muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: task.progress / 100,
                        minHeight: 3,
                        color: _statusColor(task.status),
                        backgroundColor: muted.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                tooltip: '子タスクを追加',
                icon: const Icon(Icons.add),
                onPressed: () => _openEditor(parentId: task.id),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _WbsDrop {
  final int id;
  final bool after;
  const _WbsDrop(this.id, this.after);
}

/// WBS の1行。左のつまみを長押しして、別の行の上半分／下半分へ落とすと順番が変わる。
class _WbsDragRow extends StatelessWidget {
  final int taskId;
  final String title;
  final List<Task> tasks;
  final bool highlighted;
  final bool dropAfter;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final void Function(bool after) onHover;
  final void Function(int draggedId, int targetId, bool after) onDrop;
  final Widget child;

  const _WbsDragRow({
    required this.taskId,
    required this.title,
    required this.tasks,
    required this.highlighted,
    required this.dropAfter,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onHover,
    required this.onDrop,
    required this.child,
  });

  bool _after(BuildContext context, Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return box.globalToLocal(global).dy >= box.size.height / 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (details.data == taskId) return false;
        return !descendantIds(tasks, details.data).contains(taskId);
      },
      onMove: (details) => onHover(_after(context, details.offset)),
      onAcceptWithDetails: (details) => onDrop(details.data, taskId, _after(context, details.offset)),
      builder: (context, candidate, rejected) {
        return DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: highlighted && !dropAfter ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
              bottom: highlighted && dropAfter ? BorderSide(color: scheme.primary, width: 2) : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              LongPressDraggable<int>(
                data: taskId,
                delay: const Duration(milliseconds: 180),
                onDragStarted: onDragStarted,
                onDragEnd: (_) => onDragEnded(),
                feedback: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Icon(Icons.drag_handle, size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.3)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(Icons.drag_handle, size: 18, color: scheme.onSurfaceVariant),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
