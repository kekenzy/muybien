import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:muybien_memo/main.dart';

void main() {
  testWidgets('shows a loading indicator while checking login state', (WidgetTester tester) async {
    // flutter_secure_storage にはテスト環境用のプラットフォームチャンネルが無いため、
    // ログイン判定Future は解決しない。起動直後のゲート画面のみ検証する。
    await tester.pumpWidget(const MuyBienMemoApp());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
