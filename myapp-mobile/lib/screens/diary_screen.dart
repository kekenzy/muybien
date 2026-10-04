import 'package:flutter/material.dart';

import '../config.dart';
import '../models/note_item.dart';
import 'calendar_screen.dart';
import 'memo_list_screen.dart';

enum _ViewMode { calendar, list }

/// 日記（日記と期限付きタスク）。タスク管理の ToDo / WBS と同じく、カレンダーと一覧を切り替えて表示する。
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  _ViewMode _mode = _ViewMode.calendar;
  // 切り替え時に表示する側を再読み込みし、もう片方での変更を反映する
  final _calendarReload = ValueNotifier(0);
  final _listReload = ValueNotifier(0);

  String get _hostLabel {
    try {
      return Uri.parse(apiBaseUrl).host;
    } catch (_) {
      return apiBaseUrl;
    }
  }

  @override
  void dispose() {
    _calendarReload.dispose();
    _listReload.dispose();
    super.dispose();
  }

  void _changeMode(_ViewMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    (mode == _ViewMode.calendar ? _calendarReload : _listReload).value++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日記', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            Text(
              '接続先: $_hostLabel',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
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
                  ButtonSegment(value: _ViewMode.calendar, label: Text('カレンダー'), icon: Icon(Icons.calendar_month_outlined, size: 16)),
                  ButtonSegment(value: _ViewMode.list, label: Text('一覧'), icon: Icon(Icons.list_alt_outlined, size: 16)),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => _changeMode(s.first),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _mode.index,
        children: [
          CalendarScreen(reloadSignal: _calendarReload),
          MemoListScreen(kind: NoteKind.diary, reloadSignal: _listReload),
        ],
      ),
    );
  }
}
