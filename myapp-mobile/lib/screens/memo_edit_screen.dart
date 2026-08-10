import 'package:flutter/material.dart';

import '../models/note_item.dart';
import '../services/api_client.dart';

class MemoEditScreen extends StatefulWidget {
  final NoteItem? note;
  final DateTime? initialDate;

  const MemoEditScreen({super.key, this.note, this.initialDate});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  static final _diaryColor = Colors.orange.shade700;
  static const _memoColor = Colors.indigo;

  late final TextEditingController _titleController =
      TextEditingController(text: widget.note?.title ?? '');
  late final TextEditingController _contentController =
      TextEditingController(text: widget.note?.content ?? '');
  late DateTime _date;
  late NoteKind _kind;
  bool _saving = false;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final base = widget.note?.date ?? widget.initialDate ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    // 新規は日記（Labカレンダーと共通）として保存。既存は種別を維持。
    _kind = widget.note?.kind ?? NoteKind.diary;
  }

  String get _dateLabel =>
      '${_date.year}/${_date.month.toString().padLeft(2, '0')}/${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final title = _kind == NoteKind.diary ? '' : _titleController.text;
      final content = _contentController.text;
      if (_isEditing) {
        final id = widget.note!.id;
        if (_kind == NoteKind.diary) {
          await ApiClient.instance.updateDiary(id, title, content, _date);
        } else {
          await ApiClient.instance.updateMemo(id, title, content, date: _date);
        }
      } else {
        if (_kind == NoteKind.diary) {
          await ApiClient.instance.createDiary(title, content, _date);
        } else {
          await ApiClient.instance.createMemo(title, content, date: _date);
        }
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
        title: Text('${_kind == NoteKind.diary ? '日記' : 'メモ'}を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (_kind == NoteKind.diary) {
        await ApiClient.instance.deleteDiary(widget.note!.id);
      } else {
        await ApiClient.instance.deleteMemo(widget.note!.id);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Widget _buildKindOption(NoteKind kind, String label, IconData icon, Color color) {
    final selected = _kind == kind;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _kind = kind),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.14) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? color : Colors.transparent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: selected
                      ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindSelector() {
    return Row(
      children: [
        _buildKindOption(NoteKind.diary, '日記', Icons.book_rounded, _diaryColor),
        const SizedBox(width: 10),
        _buildKindOption(NoteKind.memo, 'メモ', Icons.edit_note_rounded, _memoColor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? (_kind == NoteKind.diary ? '日記を編集' : 'メモを編集')
            : '新規'),
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
            if (!_isEditing) _buildKindSelector(),
            if (!_isEditing) const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('日付: $_dateLabel', style: const TextStyle(fontSize: 13)),
            ),
            if (_kind == NoteKind.memo) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder(), isDense: true),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '本文', border: OutlineInputBorder(), isDense: true),
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
