import 'package:flutter/material.dart';

import '../models/note_item.dart';
import 'memo_list_screen.dart';

/// 下メニューの「メモ」。日記とは別に、メモだけを一覧する。
class MemoScreen extends StatelessWidget {
  const MemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MemoListScreen(kind: NoteKind.memo);
  }
}
