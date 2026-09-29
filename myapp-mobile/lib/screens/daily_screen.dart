import 'package:flutter/material.dart';

import '../models/daily.dart';
import '../services/api_client.dart';
import 'daily_items_screen.dart';

/// 毎日やることのチェック。カレンダーの日付をタップし、下のリストでチェックを付け外しする。
class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  static const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

  List<DailyItem>? _items;
  // "itemId:YYYY-MM-DD" の集合でチェック済みを持つ
  Set<String> _checked = {};
  final Set<String> _pending = {};
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
        ApiClient.instance.listDailyItems(),
        ApiClient.instance.listDailyChecks(_month.year, _month.month),
      ]);
      setState(() {
        _items = results[0].map(DailyItem.fromJson).toList();
        _checked = results[1].map((c) => '${c['item']}:${c['date']}').toSet();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  List<DailyItem> get _activeItems => (_items ?? const <DailyItem>[]).where((i) => i.isActive).toList();

  String _key(int itemId, DateTime day) => '$itemId:${ApiClient.instance.ymd(day)}';

  bool _isChecked(int itemId, DateTime day) => _checked.contains(_key(itemId, day));

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    return day.isAfter(DateTime(now.year, now.month, now.day));
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
      _checked = {};
    });
    _load();
  }

  Future<void> _toggle(DailyItem item, DateTime day) async {
    final key = _key(item.id, day);
    if (_pending.contains(key)) return;
    final before = _checked.contains(key);
    // 先に見た目を切り替え、失敗したら戻す
    setState(() {
      _pending.add(key);
      before ? _checked.remove(key) : _checked.add(key);
    });
    try {
      final checked = await ApiClient.instance.toggleDailyCheck(item.id, day);
      setState(() => checked ? _checked.add(key) : _checked.remove(key));
    } catch (e) {
      setState(() => before ? _checked.add(key) : _checked.remove(key));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      setState(() => _pending.remove(key));
    }
  }

  Future<void> _openItems() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DailyItemsScreen()),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily'),
        actions: [
          IconButton(
            tooltip: '項目の管理',
            icon: const Icon(Icons.tune),
            onPressed: _openItems,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _error != null ? _buildError() : _buildBody(),
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
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 40),
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 4),
        _buildWeekdayRow(),
        _buildMonthGrid(),
        const SizedBox(height: 14),
        _buildSelectedDateHeader(),
        const SizedBox(height: 6),
        if (_activeItems.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: TextButton.icon(
                onPressed: _openItems,
                icon: const Icon(Icons.add),
                label: const Text('毎日やることを登録する'),
              ),
            ),
          )
        else
          ..._activeItems.map(_buildCheckTile),
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
        final color = i == 0
            ? Colors.red.shade300
            : (i == 6 ? Colors.blue.shade300 : Theme.of(context).colorScheme.onSurfaceVariant);
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

  Widget _buildMonthGrid() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday % 7; // 日曜=0
    final rows = ((leadingBlanks + daysInMonth) / 7).ceil();
    final today = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    final activeItems = _activeItems;

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final dayNum = row * 7 + col - leadingBlanks + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 54));
            }
            final day = DateTime(_month.year, _month.month, dayNum);
            final isSelected = _isSameDay(day, _selectedDate);
            final isToday = _isSameDay(day, today);
            final checkedCount = activeItems.where((i) => _isChecked(i.id, day)).length;
            final allDone = activeItems.isNotEmpty && checkedCount == activeItems.length;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.all(1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                  decoration: BoxDecoration(
                    color: allDone ? Colors.amber.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: isSelected
                        ? Border.all(color: scheme.primary, width: 2)
                        : (isToday ? Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.2) : null),
                  ),
                  child: Column(
                    children: [
                      Text(
                        allDone ? '$dayNum🎉' : '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: col == 0 ? Colors.red.shade300 : (col == 6 ? Colors.blue.shade300 : null),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 1,
                          runSpacing: 0,
                          children: activeItems.map((item) {
                            final checked = _isChecked(item.id, day);
                            return Text(
                              item.symbol,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: checked ? item.displayColor : scheme.onSurface.withValues(alpha: 0.12),
                              ),
                            );
                          }).toList(),
                        ),
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
    final activeItems = _activeItems;
    final count = activeItems.where((i) => _isChecked(i.id, d)).length;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} のDaily',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        if (activeItems.isNotEmpty)
          Text(
            '$count / ${activeItems.length}',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
      ],
    );
  }

  Widget _buildCheckTile(DailyItem item) {
    final day = _selectedDate;
    final checked = _isChecked(item.id, day);
    final future = _isFuture(day);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: checked
          ? item.displayColor.withValues(alpha: 0.14)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // 未来の日付は誤タップ防止のためチェックできない
        onTap: future ? null : () => _toggle(item, day),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(
                item.symbol,
                style: TextStyle(
                  fontSize: 22,
                  color: checked ? item.displayColor : scheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: future ? scheme.onSurface.withValues(alpha: 0.4) : null,
                  ),
                ),
              ),
              Icon(
                checked ? Icons.check_circle : Icons.radio_button_unchecked,
                color: checked ? item.displayColor : scheme.onSurface.withValues(alpha: future ? 0.15 : 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
