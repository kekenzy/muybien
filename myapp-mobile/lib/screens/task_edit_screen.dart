import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';

class TaskEditScreen extends StatefulWidget {
  /// 編集対象。カレンダーからは一部の項目しか持たないので、開いたときに API から取り直す。
  final Task? task;
  final DateTime? initialDueDate;
  final int? initialParentId;

  const TaskEditScreen({super.key, this.task, this.initialDueDate, this.initialParentId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskStatus _status = TaskStatus.todo;
  TaskPriority _priority = TaskPriority.medium;
  int? _parentId;
  DateTime? _startDate;
  DateTime? _dueDate;
  int _progress = 0;

  Task? _original;
  List<Task> _allTasks = [];
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _parentId = widget.initialParentId;
    _dueDate = widget.initialDueDate;
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final all = (await ApiClient.instance.listTasks()).map(Task.fromJson).toList();
      Task? original;
      if (_isEditing) original = Task.fromJson(await ApiClient.instance.getTask(widget.task!.id));
      if (!mounted) return;
      setState(() {
        _allTasks = all;
        _original = original;
        if (original != null) {
          _titleController.text = original.title;
          _descriptionController.text = original.description;
          _status = original.status;
          _priority = original.priority;
          _parentId = original.parentId;
          _startDate = original.startDate;
          _dueDate = original.dueDate;
          _progress = original.progress;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '未設定';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    return showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  int _nextOrder(int? parentId) {
    final siblings = _allTasks.where((t) => t.parentId == parentId);
    return siblings.fold<int>(0, (max, t) => t.order > max ? t.order : max) + 1;
  }

  String? _ymdOrNull(DateTime? d) => d == null ? null : ApiClient.instance.ymd(d);

  bool _sameDay(DateTime? a, DateTime? b) =>
      (a == null && b == null) || (a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day);

  /// 日付を変えたら期間（稼働日数）も合わせて更新する。Web の WBS はこの期間でバーを動かす。
  Map<String, dynamic> _dateFields() {
    final start = _startDate;
    final due = _dueDate;
    return {
      'start_date': _ymdOrNull(start),
      'due_date': _ymdOrNull(due),
      'duration_days': start != null && due != null ? countWorkingDays(start, due).toStringAsFixed(2) : null,
    };
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('タイトルを入力してください');
      return;
    }
    if (_startDate != null && _dueDate != null && _dueDate!.isBefore(_startDate!)) {
      _showSnack('終了日は開始日以降にしてください');
      return;
    }
    setState(() => _saving = true);
    try {
      final original = _original;
      if (original == null) {
        await ApiClient.instance.createTask({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'status': _status.apiValue,
          'priority': _priority.apiValue,
          'parent': _parentId,
          'order': _nextOrder(_parentId),
          'progress': _progress,
          ..._dateFields(),
        });
      } else {
        // 変わった項目だけ送る（先行タスクなど、アプリで扱わない項目は触らない）
        final fields = <String, dynamic>{};
        if (_titleController.text != original.title) fields['title'] = _titleController.text;
        if (_descriptionController.text != original.description) fields['description'] = _descriptionController.text;
        if (_status != original.status) fields['status'] = _status.apiValue;
        if (_priority != original.priority) fields['priority'] = _priority.apiValue;
        if (_progress != original.progress) fields['progress'] = _progress;
        if (_parentId != original.parentId) {
          fields['parent'] = _parentId;
          fields['order'] = _nextOrder(_parentId);
        }
        if (!_sameDay(_startDate, original.startDate) || !_sameDay(_dueDate, original.dueDate)) {
          fields.addAll(_dateFields());
        }
        if (fields.isNotEmpty) await ApiClient.instance.updateTask(original.id, fields);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('保存に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final childCount = descendantIds(_allTasks, widget.task!.id).length - 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('タスクを削除しますか？'),
        content: childCount > 0 ? Text('子タスク $childCount 件も一緒に削除されます。') : null,
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.deleteTask(widget.task!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('削除に失敗しました: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _buildStatusSelector() {
    // ステータスが6種類あるので折り返せるチップで並べる
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: TaskStatus.values
          .map((s) => ChoiceChip(
                label: Text(s.label, style: const TextStyle(fontSize: 12)),
                selected: _status == s,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _status = s),
              ))
          .toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return SegmentedButton<TaskPriority>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: TaskPriority.values.reversed
          .map((p) => ButtonSegment(value: p, label: Text(p.label, style: const TextStyle(fontSize: 12))))
          .toList(),
      selected: {_priority},
      onSelectionChanged: (s) => setState(() => _priority = s.first),
    );
  }

  Widget _buildParentSelector() {
    final excluded = _isEditing ? descendantIds(_allTasks, widget.task!.id) : <int>{};
    final rows = buildTaskRows(_allTasks).where((r) => !excluded.contains(r.task.id)).toList();
    return DropdownButtonFormField<int?>(
      initialValue: rows.any((r) => r.task.id == _parentId) ? _parentId : null,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('（なし）')),
        ...rows.map((r) => DropdownMenuItem<int?>(
              value: r.task.id,
              child: Text('${'　' * r.level}${r.wbsNo} ${r.task.title}', overflow: TextOverflow.ellipsis),
            )),
      ],
      onChanged: (v) => setState(() => _parentId = v),
    );
  }

  Widget _buildDateButton(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: () async {
              final picked = await _pickDate(value);
              if (picked != null) onChanged(picked);
            },
            icon: const Icon(Icons.event, size: 16),
            label: Text('$label: ${_dateLabel(value)}', style: const TextStyle(fontSize: 12)),
          ),
        ),
        if (value != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close, size: 16),
            tooltip: '$labelをクリア',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'タスクを編集' : '新規タスク'),
        actions: [
          if (_isEditing && !_loading && _loadError == null)
            IconButton(onPressed: _saving ? null : _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('再読み込み')),
            ],
          ),
        ),
      );
    }
    final duration = _startDate != null && _dueDate != null && !_dueDate!.isBefore(_startDate!)
        ? countWorkingDays(_startDate!, _dueDate!)
        : null;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 12),
                _label('ステータス'),
                _buildStatusSelector(),
                const SizedBox(height: 12),
                _label('優先度'),
                Align(alignment: Alignment.centerLeft, child: _buildPrioritySelector()),
                const SizedBox(height: 12),
                _label('親タスク'),
                _buildParentSelector(),
                const SizedBox(height: 12),
                _label(duration != null ? '日程（期間 $duration 稼働日）' : '日程'),
                _buildDateButton('開始日', _startDate, (v) => setState(() => _startDate = v)),
                const SizedBox(height: 6),
                _buildDateButton('終了日', _dueDate, (v) => setState(() => _dueDate = v)),
                const SizedBox(height: 12),
                _label('進捗 $_progress%'),
                Slider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '$_progress%',
                  onChanged: (v) => setState(() => _progress = v.round()),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: '詳細',
                    border: OutlineInputBorder(),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  minLines: 6,
                  maxLines: null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(vertical: 10)),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
