import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task>? _tasks;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await ApiClient.instance.listTasks();
      final tasks = results.map(Task.fromJson).toList()
        ..sort((a, b) {
          final ad = a.dueDate;
          final bd = b.dueDate;
          if (ad == null && bd == null) return b.createdAt.compareTo(a.createdAt);
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
      setState(() => _tasks = tasks);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _openEditor({Task? task}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleDone(Task task) async {
    final nextStatus = task.status == TaskStatus.done ? TaskStatus.todo : TaskStatus.done;
    try {
      await ApiClient.instance.updateTask(
        task.id,
        task.title,
        task.description,
        nextStatus.apiValue,
        dueDate: task.dueDate,
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
      case TaskStatus.todo:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('タスク')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ],
      );
    }
    final tasks = _tasks;
    if (tasks == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tasks.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('タスクはまだありません。＋ボタンで追加できます。')),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final done = task.status == TaskStatus.done;
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _statusColor(task.status).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.status.label,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _statusColor(task.status)),
                              ),
                            ),
                            if (task.dueDate != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.event, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 2),
                              Text(
                                _formatDate(task.dueDate!),
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                            color: done ? Theme.of(context).colorScheme.onSurfaceVariant : null,
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
          ),
        );
      },
    );
  }
}
