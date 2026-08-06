import 'package:flutter/material.dart';

import '../models/memo.dart';
import '../services/api_client.dart';
import 'login_screen.dart';
import 'memo_edit_screen.dart';

class MemoListScreen extends StatefulWidget {
  const MemoListScreen({super.key});

  @override
  State<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  List<Memo>? _memos;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final raw = await ApiClient.instance.listMemos();
      setState(() => _memos = raw.map(Memo.fromJson).toList());
    } catch (e) {
      setState(() => _error = 'メモの取得に失敗しました');
    }
  }

  Future<void> _logout() async {
    await ApiClient.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openEditor({Memo? memo}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MemoEditScreen(memo: memo)),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メモ'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final memos = _memos;
    if (memos == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (memos.isEmpty) {
      return const Center(child: Text('メモはまだありません。＋ボタンで追加できます。'));
    }
    return ListView.separated(
      itemCount: memos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final memo = memos[index];
        return ListTile(
          title: Text(memo.title.isEmpty ? '(無題)' : memo.title),
          subtitle: Text(
            memo.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => _openEditor(memo: memo),
        );
      },
    );
  }
}
