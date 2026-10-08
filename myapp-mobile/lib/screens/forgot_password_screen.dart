import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// パスワードを忘れたときの再設定メール送信画面。
/// 新しいパスワードの設定は、メールのリンクから開く Web の画面で行う。
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _sentMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'メールアドレスを正しく入力してください');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await ApiClient.instance.requestPasswordReset(email);
      setState(() => _sentMessage = message);
    } on ApiException catch (e) {
      setState(() => _error = e.statusCode == 429
          ? '短時間に送信が続いたため、しばらく時間をおいてからお試しください'
          : e.message);
    } catch (_) {
      setState(() => _error = 'サーバーに接続できません');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('パスワードの再設定')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _sentMessage != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_read_outlined, size: 48, color: colors.primary),
                    const SizedBox(height: 16),
                    Text(_sentMessage!),
                    const SizedBox(height: 12),
                    Text(
                      'メールのリンクをタップすると、ブラウザで新しいパスワードを設定できます（有効期限: 1時間）。'
                      '設定後、このアプリに戻ってログインしてください。\n'
                      'メールが届かない場合は、迷惑メールフォルダもご確認ください。',
                      style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('ログイン画面に戻る'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('登録しているメールアドレスを入力してください。パスワード再設定用のリンクをお送りします。'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'メールアドレス', border: OutlineInputBorder()),
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
                          : const Text('再設定メールを送信'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
