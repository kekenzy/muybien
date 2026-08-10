import 'package:flutter/material.dart';

import '../models/note_item.dart';
import 'memo_edit_screen.dart';

/// メモ・日記の閲覧画面。右上の鉛筆アイコンから編集画面へ遷移する。
class NoteDetailScreen extends StatefulWidget {
  final NoteItem note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late NoteItem _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  String get _dateLabel {
    final d = _note.date;
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MemoEditScreen(note: _note)),
    );
    if (!mounted) return;
    if (changed == true) {
      // 一覧側の再読み込みが必要なため、閲覧画面ごと呼び出し元に伝播する
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMemo = _note.kind == NoteKind.memo;
    return Scaffold(
      appBar: AppBar(
        title: Text(_note.kindLabel),
        actions: [
          IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                _dateLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isMemo && _note.title.isNotEmpty) ...[
              Text(
                _note.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
            ],
            SelectableText(
              _note.content.isEmpty ? '(本文なし)' : _note.content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
