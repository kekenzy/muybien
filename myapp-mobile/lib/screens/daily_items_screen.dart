import 'package:flutter/material.dart';

import '../models/daily.dart';
import '../services/api_client.dart';

/// Daily項目（毎日やること）の追加・編集・削除。戻るときに変更があれば true を返す。
class DailyItemsScreen extends StatefulWidget {
  const DailyItemsScreen({super.key});

  @override
  State<DailyItemsScreen> createState() => _DailyItemsScreenState();
}

class _DailyItemsScreenState extends State<DailyItemsScreen> {
  List<DailyItem>? _items;
  String? _error;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await ApiClient.instance.listDailyItems();
      setState(() => _items = results.map(DailyItem.fromJson).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  Future<void> _openEditor([DailyItem? item]) async {
    final items = _items ?? const <DailyItem>[];
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DailyItemEditor(
        item: item,
        initialColor: dailyColorPresets[items.length % dailyColorPresets.length],
      ),
    );
    if (result == null) return;

    try {
      if (result.delete && item != null) {
        await ApiClient.instance.deleteDailyItem(item.id);
      } else if (item != null) {
        await ApiClient.instance.updateDailyItem(item.id, result.fields);
      } else {
        final order = items.fold<int>(0, (max, i) => i.order > max ? i.order : max) + 1;
        await ApiClient.instance.createDailyItem({...result.fields, 'order': order});
      }
      _changed = true;
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('毎日やること')),
        body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
        floatingActionButton: FloatingActionButton(
          heroTag: 'daily_items_fab',
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))],
      );
    }
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Text('＋ボタンから毎日やることを登録してください。', textAlign: TextAlign.center),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 80),
      children: items.map((item) {
        return ListTile(
          leading: Text(item.symbol, style: TextStyle(fontSize: 22, color: item.displayColor)),
          title: Text(
            item.title,
            style: TextStyle(color: item.isActive ? null : Theme.of(context).disabledColor),
          ),
          subtitle: item.isActive ? null : const Text('カレンダーに表示しない'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openEditor(item),
        );
      }).toList(),
    );
  }
}

class _EditResult {
  final Map<String, dynamic> fields;
  final bool delete;
  const _EditResult(this.fields, {this.delete = false});
}

class _DailyItemEditor extends StatefulWidget {
  final DailyItem? item;
  final String initialColor;

  const _DailyItemEditor({this.item, required this.initialColor});

  @override
  State<_DailyItemEditor> createState() => _DailyItemEditorState();
}

class _DailyItemEditorState extends State<_DailyItemEditor> {
  late final TextEditingController _title;
  late String _color;
  late String _mark;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _color = item?.color ?? widget.initialColor;
    _mark = item?.mark ?? 'star';
    _isActive = item?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('「${widget.item!.title}」を削除しますか？'),
        content: const Text('過去のチェック記録も削除されます。記録を残したい場合は「カレンダーに表示する」をオフにしてください。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('削除')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const _EditResult({}, delete: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = parseDailyColor(_color);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.item == null ? '項目を追加' : '項目を編集',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _title,
            autofocus: widget.item == null,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'やること', hintText: '例：筋トレ、英語30分'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          const Text('印', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: dailyMarks.entries.map((e) {
              final selected = e.key == _mark;
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _mark = e.key),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? scheme.primary : scheme.outlineVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(e.value, style: TextStyle(fontSize: 20, color: color)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          const Text('色', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: dailyColorPresets.map((hex) {
              final selected = hex == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: parseDailyColor(hex),
                    border: Border.all(color: selected ? scheme.onSurface : Colors.transparent, width: 2.5),
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.item != null) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('カレンダーに表示する'),
              subtitle: const Text('オフにしても過去のチェックは残ります'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.item != null)
                TextButton(
                  onPressed: _confirmDelete,
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('削除'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _title.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_EditResult({
                          'title': _title.text.trim(),
                          'color': _color,
                          'mark': _mark,
                          'is_active': _isActive,
                        })),
                child: Text(widget.item == null ? '追加する' : '更新する'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
