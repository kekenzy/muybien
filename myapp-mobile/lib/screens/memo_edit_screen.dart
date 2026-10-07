import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/note_item.dart';
import '../services/api_client.dart';
import 'photo_viewer.dart';

class MemoEditScreen extends StatefulWidget {
  final NoteItem? note;
  final DateTime? initialDate;
  final NoteKind? initialKind;

  const MemoEditScreen({super.key, this.note, this.initialDate, this.initialKind});

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
  final _picker = ImagePicker();
  late List<DiaryPhoto> _photos;
  final List<XFile> _pending = [];
  final List<int> _removedPhotoIds = [];

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    final base = widget.note?.date ?? widget.initialDate ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _kind = widget.note?.kind ?? widget.initialKind ?? NoteKind.diary;
    _photos = List<DiaryPhoto>.from(widget.note?.photos ?? const []);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file != null) setState(() => _pending.add(file));
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
      final int recordId;
      if (_isEditing) {
        recordId = widget.note!.id;
        if (_kind == NoteKind.diary) {
          await ApiClient.instance.updateDiary(recordId, title, content, _date);
        } else {
          await ApiClient.instance.updateMemo(recordId, title, content, date: _date);
        }
      } else if (_kind == NoteKind.diary) {
        final created = await ApiClient.instance.createDiary(title, content, _date);
        recordId = created['id'] as int;
      } else {
        final created = await ApiClient.instance.createMemo(title, content, date: _date);
        recordId = created['id'] as int;
      }
      for (final photoId in _removedPhotoIds) {
        if (_kind == NoteKind.diary) {
          await ApiClient.instance.deleteDiaryPhoto(recordId, photoId);
        } else {
          await ApiClient.instance.deleteMemoPhoto(recordId, photoId);
        }
      }
      for (final file in _pending) {
        final bytes = await file.readAsBytes();
        if (_kind == NoteKind.diary) {
          await ApiClient.instance.uploadDiaryPhoto(recordId, bytes, file.name);
        } else {
          await ApiClient.instance.uploadMemoPhoto(recordId, bytes, file.name);
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

  void _openViewer(List<ImageProvider> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewer(images: images, initialIndex: index),
      ),
    );
  }

  Widget _photoCell({
    required List<ImageProvider> images,
    required int index,
    required VoidCallback onRemove,
  }) {
    final image = images[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _openViewer(images, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(image: image, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotos() {
    final kept = _photos.where((photo) => !_removedPhotoIds.contains(photo.id)).toList();
    // 保存済み・追加予定をまとめて、ビューアで続けてスワイプできるようにする
    final images = <ImageProvider>[
      for (final photo in kept) NetworkImage(photo.url),
      for (final file in _pending) FileImage(File(file.path)),
    ];
    Widget pendingCell(int index) {
      return _photoCell(
        images: images,
        index: kept.length + index,
        onRemove: () => setState(() => _pending.removeAt(index)),
      );
    }

    final cells = <Widget>[
      for (var i = 0; i < kept.length; i++)
        _photoCell(
          images: images,
          index: i,
          onRemove: () => setState(() => _removedPhotoIds.add(kept[i].id)),
        ),
      for (var i = 0; i < _pending.length; i++) pendingCell(i),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cells.isNotEmpty)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            children: cells,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined, size: 16),
                label: const Text('カメラ', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('ファイル', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
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
            : (_kind == NoteKind.diary ? '日記を追加' : 'メモを追加')),
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
            if (!_isEditing && widget.initialKind == null) _buildKindSelector(),
            if (!_isEditing && widget.initialKind == null) const SizedBox(height: 12),
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
                autofocus: _kind == NoteKind.diary,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '本文', border: OutlineInputBorder(), isDense: true),
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            if (_kind == NoteKind.diary || _kind == NoteKind.memo) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 168),
                child: SingleChildScrollView(child: _buildPhotos()),
              ),
            ],
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
