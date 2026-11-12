import 'package:calc/core/di/locator.dart';
import 'package:calc/core/services/theme_service.dart';
import 'package:calc/features/calculator/services/history_service.dart';
import 'package:calc/features/calculator/views/calculator_view.dart';
import 'package:calc/features/promo/services/promo_service.dart';
import 'package:calc/features/promo/views/promo_thanks_dialog.dart';
import 'package:calc/features/support/services/support_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _campaign = PromoCampaign(package: 'com.akidesoft.newgame', name: 'Yeni Oyun');

Future<PromoService> _service({
  PromoCampaign? campaign = _campaign,
  List<Uri>? launched,
  List<String>? events,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = PromoService(
    prefs,
    fetch: () async => campaign,
    launch: (uri) async {
      launched?.add(uri);
      return true;
    },
    logEvent: (name, params) => events?.add('$name:${params['source'] ?? ''}'),
  );
  await service.load();
  return service;
}

void main() {
  group('PromoCampaign.fromValues', () {
    test('kapalıyken kampanya yok', () {
      expect(
        PromoCampaign.fromValues(
            enabled: false, package: 'com.akidesoft.newgame', name: 'X'),
        isNull,
      );
    });

    test('geçerli değerlerle kampanya ve Play adresi', () {
      final c = PromoCampaign.fromValues(
          enabled: true, package: ' com.akidesoft.newgame ', name: ' Yeni Oyun ');
      expect(c!.package, 'com.akidesoft.newgame');
      expect(c.name, 'Yeni Oyun');
      expect(c.storeUri.toString(),
          'https://play.google.com/store/apps/details?id=com.akidesoft.newgame');
    });

    test('boş ad, bozuk paket ve uygulamanın kendisi reddedilir', () {
      for (final pkg in ['', 'oyun', 'com.x/../y', 'com.akidesoft.calc']) {
        expect(
          PromoCampaign.fromValues(enabled: true, package: pkg, name: 'X'),
          isNull,
          reason: pkg,
        );
      }
      expect(
        PromoCampaign.fromValues(
            enabled: true, package: 'com.akidesoft.newgame', name: '  '),
        isNull,
      );
    });
  });

  group('PromoService', () {
    test('kampanya yokken hiçbir şey gösterilmez', () async {
      final s = await _service(campaign: null);
      expect(s.showMenuDot, isFalse);
      expect(s.shouldShowAfterAd, isFalse);
    });

    test('okuma hata verirse tanıtım kapalı kalır', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = PromoService(prefs, fetch: () async => throw Exception('ağ yok'));
      await s.load();
      expect(s.campaign, isNull);
    });

    test('menü noktası menü açılınca kaybolur', () async {
      final s = await _service();
      expect(s.showMenuDot, isTrue);
      await s.markMenuSeen();
      expect(s.showMenuDot, isFalse);
    });

    test('reklam sonrası kart en fazla 3 kez gösterilir', () async {
      final s = await _service();
      for (var i = 0; i < PromoService.maxAfterAdShows; i++) {
        expect(s.shouldShowAfterAd, isTrue);
        await s.markAfterAdShown();
      }
      expect(s.shouldShowAfterAd, isFalse);
    });

    test('sayfa açılınca kart bir daha çıkmaz, Play adresi açılır', () async {
      final launched = <Uri>[];
      final events = <String>[];
      final s = await _service(launched: launched, events: events);
      await s.open('after_ad');
      expect(launched.single, _campaign.storeUri);
      expect(events, ['promo_open:after_ad']);
      expect(s.shouldShowAfterAd, isFalse);
    });
  });

  group('arayüz', () {
    tearDown(() => getIt.reset());

    Future<void> pumpCalculator(WidgetTester tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<HistoryService>.value(
                value: HistoryService(prefs)),
            ChangeNotifierProvider<ThemeService>(
                create: (_) => ThemeService(prefs)),
            Provider<SupportStateService>.value(
                value: SupportStateService(prefs)),
          ],
          child: const MaterialApp(home: CalculatorView()),
        ),
      );
    }

    testWidgets('kampanya varken menüde satır ve nokta var, satır Play\'i açar',
        (tester) async {
      final launched = <Uri>[];
      final s = await _service(launched: launched);
      getIt.registerSingleton<PromoService>(s);
      await pumpCalculator(tester);

      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isTrue);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Yeni Oyun'), findsOneWidget);
      expect(s.showMenuDot, isFalse);

      await tester.tap(find.text('Yeni Oyun'));
      await tester.pumpAndSettle();
      expect(launched.single, _campaign.storeUri);
    });

    testWidgets('kampanya yokken menüde tanıtım satırı ve nokta yok',
        (tester) async {
      final s = await _service(campaign: null);
      getIt.registerSingleton<PromoService>(s);
      await pumpCalculator(tester);

      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.new_releases_outlined), findsNothing);
    });

    testWidgets('teşekkür kartı uygulamayı açar', (tester) async {
      final launched = <Uri>[];
      final s = await _service(launched: launched);
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => PromoThanksDialog(promoService: s),
            ),
            child: const Text('aç'),
          ),
        ),
      ));
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(launched.single, _campaign.storeUri);
    });
  });
}
