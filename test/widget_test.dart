// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:calc/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:calc/features/calculator/services/history_service.dart';
import 'package:calc/core/services/theme_service.dart';
import 'package:calc/features/calculator/viewmodels/calculator_viewmodel.dart';

void main() {
  testWidgets('Calculator app test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final historyService = HistoryService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<HistoryService>.value(
            value: historyService,
          ),
          ChangeNotifierProvider<ThemeService>(
            create: (_) => ThemeService(prefs),
          ),
          ChangeNotifierProvider<CalculatorViewModel>(
            create: (context) => CalculatorViewModel(
              context.read<HistoryService>(),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Test basic number input
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('123'), findsOneWidget);

    // Test basic calculation
    await tester.tap(find.text('+'));
    await tester.tap(find.text('4'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.text('= 168'), findsOneWidget);

    // Test clear functionality
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(find.text(''), findsOneWidget);

    // Test parentheses
    await tester.tap(find.text('2'));
    await tester.tap(find.text('×'));
    await tester.tap(find.text('()'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('4'));
    await tester.tap(find.text('()'));
    await tester.pump();
    expect(find.text('= 14'), findsOneWidget);
  });
}
