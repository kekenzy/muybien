import 'package:flutter/material.dart';

import '../models/note_item.dart';
import 'memo_edit_screen.dart';
import 'photo_viewer.dart';

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

  void _openPhoto(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewer(image: NetworkImage(url)),
      ),
    );
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
            GestureDetector(
              onTap: _note.kind == NoteKind.diary ? _edit : null,
              child: Text(
                _note.content.isEmpty ? '(本文なし)' : _note.content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
            if (_note.photos.isNotEmpty) ...[
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _note.photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final photo = _note.photos[index];
                  return GestureDetector(
                    onTap: () => _openPhoto(photo.url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0x11000000),
                          child: Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
