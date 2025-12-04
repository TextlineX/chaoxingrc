// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chaoxingrc/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chaoxingrc/app/providers/theme_provider.dart';
import 'package:chaoxingrc/app/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 使用模拟的 SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // 初始化提供者
    final themeProvider = ThemeProvider();
    final userProvider = UserProvider();

    // 等待异步初始化完成
    await themeProvider.init(notify: false);
    // UserProvider 初始化可能涉及复杂逻辑，这里简单处理
    // await userProvider.init(notify: false);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: userProvider),
        ],
        child: const App(),
      ),
    );

    // 等待所有异步任务完成，减少 pumpAndSettle 的持续时间，避免超时
    // 很多时候 pumpAndSettle 会因为无限动画（如 ProgressIndicator）而超时
    // 所以我们只 pump 一次，或者使用 pump(Duration)
    await tester.pump();

    // 验证应用启动
    // 这里的文本可能需要根据实际 UI 进行调整，例如 '登录' 或其他
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
