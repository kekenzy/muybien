import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/api_client.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? task;
  final DateTime? initialDueDate;

  const TaskEditScreen({super.key, this.task, this.initialDueDate});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _descriptionController =
      TextEditingController(text: widget.task?.description ?? '');
  late TaskStatus _status;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _status = widget.task?.status ?? TaskStatus.todo;
    _dueDate = widget.task?.dueDate ?? widget.initialDueDate;
  }

  String get _dueDateLabel {
    final d = _dueDate;
    if (d == null) return '未設定';
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final title = _titleController.text;
      final description = _descriptionController.text;
      if (_isEditing) {
        await ApiClient.instance.updateTask(
          widget.task!.id,
          title,
          description,
          _status.apiValue,
          dueDate: _dueDate,
        );
      } else {
        await ApiClient.instance.createTask(
          title,
          description,
          _status.apiValue,
          dueDate: _dueDate,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('タスクを削除しますか？'),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Widget _buildStatusSelector() {
    return SegmentedButton<TaskStatus>(
      segments: TaskStatus.values
          .map((s) => ButtonSegment(value: s, label: Text(s.label, style: const TextStyle(fontSize: 12))))
          .toList(),
      selected: {_status},
      onSelectionChanged: (s) => setState(() => _status = s.first),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'タスクを編集' : '新規タスク'),
        actions: [
          if (_isEditing)
            IconButton(onPressed: _saving ? null : _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: _buildStatusSelector()),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    onPressed: _pickDueDate,
                    icon: const Icon(Icons.event, size: 16),
                    label: Text('期限: $_dueDateLabel', style: const TextStyle(fontSize: 13)),
                  ),
                ),
                if (_dueDate != null)
                  IconButton(
                    onPressed: () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '期限をクリア',
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '詳細', border: OutlineInputBorder(), isDense: true),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(vertical: 10)),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
