import 'package:flutter/material.dart';

import '../models/note_item.dart';
import '../services/api_client.dart';
import 'memo_edit_screen.dart';
import 'note_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  List<NoteItem>? _notes;
  String? _error;
  late DateTime _month; // 表示中の月（day=1固定）
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        ApiClient.instance.listMemos(),
        ApiClient.instance.listDiaries(),
      ]);
      final memos = results[0].map(NoteItem.fromMemoJson);
      final diaries = results[1].map(NoteItem.fromDiaryJson);
      final notes = [...memos, ...diaries]..sort((a, b) => a.date.compareTo(b.date));
      setState(() => _notes = notes);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  List<NoteItem> _notesOn(DateTime day) {
    final notes = _notes;
    if (notes == null) return const [];
    return notes.where((n) => n.date.year == day.year && n.date.month == day.month && n.date.day == day.day).toList();
  }

  static const _memoColor = Colors.indigo;
  static final _diaryColor = Colors.orange.shade700;

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  Future<void> _openEditor({DateTime? initialDate}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MemoEditScreen(initialDate: initialDate)),
    );
    if (changed == true) _load();
  }

  Future<void> _openDetail(NoteItem note) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カレンダー')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null ? _buildError() : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(initialDate: _selectedDate),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildError() {
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

  Widget _buildBody() {
    if (_notes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selectedNotes = _notesOn(_selectedDate);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 80),
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 4),
        _buildWeekdayRow(),
        _buildMonthGrid(),
        const SizedBox(height: 6),
        _buildLegend(),
        const SizedBox(height: 12),
        _buildSelectedDateHeader(),
        const SizedBox(height: 6),
        if (selectedNotes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('この日のメモ・日記はありません。', style: TextStyle(fontSize: 13))),
          )
        else
          ...selectedNotes.map(_buildNoteTile),
      ],
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, size: 22),
          visualDensity: VisualDensity.compact,
        ),
        Text(
          '${_month.year}年${_month.month}月',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right, size: 22),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildWeekdayRow() {
    return Row(
      children: List.generate(7, (i) {
        final color = i == 0 ? Colors.red.shade300 : (i == 6 ? Colors.blue.shade300 : Theme.of(context).colorScheme.onSurfaceVariant);
        return Expanded(
          child: Center(
            child: Text(
              _weekdayLabels[i],
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1)),
            ]),
          ),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        item(_diaryColor, '日記'),
        const SizedBox(width: 12),
        item(_memoColor, 'メモ'),
      ],
    );
  }

  Widget _buildMonthGrid() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday % 7; // 日曜=0
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 42));
            }
            final day = DateTime(_month.year, _month.month, dayNum);
            final isSelected = _isSameDay(day, _selectedDate);
            final isToday = _isSameDay(day, today);
            final dayNotes = _notesOn(day);
            final hasMemo = dayNotes.any((n) => n.kind == NoteKind.memo);
            final hasDiary = dayNotes.any((n) => n.kind == NoteKind.diary);
            final hasNotes = hasMemo || hasDiary;
            final dotColor = isSelected ? Theme.of(context).colorScheme.onPrimary : null;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  height: 42,
                  margin: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (hasNotes ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Colors.transparent),
                    borderRadius: BorderRadius.circular(9),
                    border: isToday && !isSelected
                        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : (col == 0 ? Colors.red.shade300 : (col == 6 ? Colors.blue.shade300 : null)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 7,
                        child: hasNotes
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (hasDiary)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dotColor ?? _diaryColor,
                                        boxShadow: isSelected
                                            ? null
                                            : [BoxShadow(color: _diaryColor.withValues(alpha: 0.5), blurRadius: 3, offset: const Offset(0, 1))],
                                      ),
                                    ),
                                  if (hasDiary && hasMemo) const SizedBox(width: 4),
                                  if (hasMemo)
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: dotColor ?? _memoColor,
                                        boxShadow: isSelected
                                            ? null
                                            : [BoxShadow(color: _memoColor.withValues(alpha: 0.5), blurRadius: 3, offset: const Offset(0, 1))],
                                      ),
                                    ),
                                ],
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildSelectedDateHeader() {
    final d = _selectedDate;
    return Text(
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} のメモ・日記',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildNoteTile(NoteItem note) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(note),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: note.kind == NoteKind.diary ? _diaryColor.withValues(alpha: 0.15) : _memoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  note.kindLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: note.kind == NoteKind.diary ? _diaryColor : Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (note.kind == NoteKind.memo)
                Expanded(
                  child: Text(
                    note.title.isEmpty ? '(無題)' : note.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Expanded(
                  child: Text(
                    note.content.isEmpty ? '(本文なし)' : note.content,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
