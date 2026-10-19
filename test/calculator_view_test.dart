import 'package:calc/features/calculator/services/history_service.dart';
import 'package:calc/features/calculator/views/calculator_view.dart';
import 'package:calc/features/feedback/services/rating_prompt_service.dart';
import 'package:calc/features/support/services/support_state_service.dart';
import 'package:calc/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HistoryService>.value(
          value: HistoryService(prefs),
        ),
        ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService(prefs)),
        Provider<SupportStateService>.value(value: SupportStateService(prefs)),
        Provider<RatingPromptService>.value(value: RatingPromptService(prefs)),
      ],
      child: const MaterialApp(home: CalculatorView()),
    ),
  );
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pump();
}

Future<void> _type(WidgetTester tester, String keys) async {
  for (final k in keys.split('')) {
    await _tap(tester, k);
  }
}

void main() {
  testWidgets('tuşlar × ÷ % olarak görünür, * ve / görünmez',
      (tester) async {
    await _pump(tester);
    expect(find.text('×'), findsOneWidget);
    expect(find.text('÷'), findsOneWidget);
    expect(find.text('%'), findsOneWidget);
    expect(find.text('*'), findsNothing);
    expect(find.text('/'), findsNothing);
  });

  testWidgets('6.13 + 8.54 = 14.67', (tester) async {
    await _pump(tester);
    await _type(tester, '6.13+8.54=');
    expect(find.text('14.67'), findsOneWidget);
  });

  testWidgets('129.6 + 51.8 = 181.4', (tester) async {
    await _pump(tester);
    await _type(tester, '129.6+51.8=');
    expect(find.text('181.4'), findsOneWidget);
  });

  testWidgets('6 × 1.2 = 7.2', (tester) async {
    await _pump(tester);
    await _type(tester, '6');
    await _tap(tester, '×');
    await _type(tester, '1.2=');
    expect(find.text('7.2'), findsOneWidget);
  });

  testWidgets('48 ÷ 6 = 8', (tester) async {
    await _pump(tester);
    await _type(tester, '48');
    await _tap(tester, '÷');
    await _type(tester, '6=');
    expect(find.text('8'), findsWidgets);
  });

  testWidgets('50% = 0.5', (tester) async {
    await _pump(tester);
    await _type(tester, '50');
    await _tap(tester, '%');
    await _tap(tester, '=');
    expect(find.text('0.5'), findsOneWidget);
  });

  testWidgets('200 × 10% = 20', (tester) async {
    await _pump(tester);
    await _type(tester, '200');
    await _tap(tester, '×');
    await _type(tester, '10');
    await _tap(tester, '%');
    await _tap(tester, '=');
    expect(find.text('20'), findsWidgets);
  });

  testWidgets('% boş ifadeye eklenmez', (tester) async {
    await _pump(tester);
    await _tap(tester, '%');
    expect(find.text('0'), findsWidgets);
    expect(find.text('%'), findsOneWidget);
  });

  group('girilen sayı ekranda olduğu gibi çizilir', () {
    testWidgets('"5." sonundaki nokta görünür', (tester) async {
      await _pump(tester);
      await _type(tester, '5.');
      expect(find.text('5.'), findsOneWidget);
    });

    testWidgets('"5.0" sondaki sıfır görünür', (tester) async {
      await _pump(tester);
      await _type(tester, '5.0');
      expect(find.text('5.0'), findsOneWidget);
    });

    testWidgets('"0.05" doğru çizilir', (tester) async {
      await _pump(tester);
      await _type(tester, '0.05');
      expect(find.text('0.05'), findsOneWidget);
    });

    testWidgets('"1234.50" binlik ayraç ve sıfır korunur', (tester) async {
      await _pump(tester);
      await _type(tester, '1234.50');
      expect(find.text('1.234.50'), findsOneWidget);
    });

    testWidgets('aynı sayıda ikinci nokta yok sayılır', (tester) async {
      await _pump(tester);
      await _type(tester, '1.2.3');
      expect(find.text('1.23'), findsOneWidget);
    });

    testWidgets('"." ile başlayınca 0. olur', (tester) async {
      await _pump(tester);
      await _type(tester, '.5');
      expect(find.text('0.5'), findsOneWidget);
    });

    testWidgets('baştaki sıfırlar yığılmaz', (tester) async {
      await _pump(tester);
      await _type(tester, '007');
      expect(find.text('7'), findsWidgets);
      expect(find.text('007'), findsNothing);
    });

    testWidgets('19 haneli sayı bozulmadan çizilir', (tester) async {
      await _pump(tester);
      await _type(tester, '1234567890123456789');
      expect(find.text('1.234.567.890.123.456.789'), findsOneWidget);
    });
  });
}
