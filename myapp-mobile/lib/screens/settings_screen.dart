import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_client.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String get _hostLabel {
    try {
      return Uri.parse(apiBaseUrl).host;
    } catch (_) {
      return apiBaseUrl;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('ログアウト')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiClient.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('アプリ情報', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('接続先'),
            subtitle: Text(_hostLabel),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('ログアウト', style: TextStyle(color: Colors.redAccent)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
