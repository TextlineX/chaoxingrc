// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:chaoxingrc/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chaoxingrc/app/providers/theme_provider.dart';
import 'package:chaoxingrc/app/providers/user_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 初始化提供者
    final themeProvider = ThemeProvider();
    final userProvider = UserProvider();

    await themeProvider.init();
    await userProvider.init();

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

    // 验证应用启动
    expect(find.text('超星网盘'), findsOneWidget);
  });
}
