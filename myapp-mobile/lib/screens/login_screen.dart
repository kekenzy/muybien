import 'package:flutter/material.dart';

import '../config.dart';
import '../services/api_client.dart';
import 'forgot_password_screen.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  String get _hostLabel {
    try {
      return Uri.parse(apiBaseUrl).host;
    } catch (_) {
      return apiBaseUrl;
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ApiClient.instance.login(_usernameController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.statusCode == 401
          ? 'ユーザー名またはパスワードが正しくありません'
          : 'ログインに失敗しました（${e.statusCode}）');
    } catch (_) {
      setState(() => _error = 'サーバーに接続できません（接続先: $_hostLabel）');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('永井のLab メモ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  '接続先: $_hostLabel',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'ユーザー名', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード', border: OutlineInputBorder()),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('ログイン'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          ),
                  child: const Text('パスワードをお忘れの方'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
