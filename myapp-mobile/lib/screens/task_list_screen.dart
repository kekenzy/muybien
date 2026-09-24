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
  bool _showClosed = true;
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
          IconButton(
            tooltip: _showClosed ? '完了・中止を隠す' : '完了・中止も表示',
            icon: Icon(_showClosed ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _showClosed = !_showClosed),
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

  Widget _buildTodo(List<Task> tasks) {
    final titleById = {for (final t in _tasks!) t.id: t.title};
    final children = <Widget>[];
    for (final status in TaskStatus.values) {
      final group = tasks.where((t) => t.status == status).toList()..sort(_compareTasks);
      if (group.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(status.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('${group.length}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ));
      for (final task in group) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _buildTodoCard(task, task.parentId != null ? titleById[task.parentId] : null),
        ));
      }
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 80),
      children: children,
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
    return _card(
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
  }

  // ---- WBS（階層） ----

  Widget _buildWbs(List<Task> tasks) {
    final rows = buildTaskRows(tasks, collapsed: _collapsed);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => _buildWbsRow(rows[index]),
    );
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

  Widget _buildWbsRow(TaskRow row) {
    final task = row.task;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final done = task.status == TaskStatus.done;
    return Padding(
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
    );
  }
}
