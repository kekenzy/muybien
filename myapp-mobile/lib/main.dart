import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/memo_list_screen.dart';
import 'services/api_client.dart';

void main() {
  runApp(const MuyBienMemoApp());
}

class MuyBienMemoApp extends StatelessWidget {
  const MuyBienMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '永井のLab メモ',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiClient.instance.isLoggedIn,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? const MemoListScreen() : const LoginScreen();
      },
    );
  }
}
