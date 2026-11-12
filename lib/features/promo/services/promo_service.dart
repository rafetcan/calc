import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Uzaktan (Firebase Remote Config) açılıp kapatılan kendi uygulama tanıtımı.
class PromoCampaign {
  final String package;
  final String name;

  const PromoCampaign({required this.package, required this.name});

  static const _ownPackage = 'com.akidesoft.calc';
  static final _packagePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$');

  /// Uzak değerlerden kampanya üretir; kapalıysa ya da değerler geçersizse
  /// `null` döner (tanıtım hiç görünmez).
  static PromoCampaign? fromValues({
    required bool enabled,
    required String package,
    required String name,
  }) {
    final pkg = package.trim();
    final title = name.trim();
    if (!enabled || title.isEmpty) return null;
    if (pkg == _ownPackage || !_packagePattern.hasMatch(pkg)) return null;
    return PromoCampaign(package: pkg, name: title);
  }

  /// `referrer`, tanıtılan uygulamanın Play Console edinme raporunda bu
  /// uygulamadan gelenlerin ayrı görünmesini sağlar (Analytics gerekmez).
  Uri get storeUri => Uri.https('play.google.com', '/store/apps/details', {
        'id': package,
        'referrer': 'utm_source=calc&utm_medium=promo',
      });
}

typedef PromoFetcher = Future<PromoCampaign?> Function();
typedef PromoLauncher = Future<bool> Function(Uri uri);
typedef PromoEventLogger = void Function(String name, Map<String, Object> params);

/// Tanıtımın nerede ve kaç kez gösterileceğini yönetir. Kalp her zaman
/// reklam açar; tanıtım yalnızca reklamdan sonraki teşekkür kartında ve
/// menüde görünür.
class PromoService extends ChangeNotifier {
  /// Reklam sonrası kart aynı kampanya için en fazla bu kadar gösterilir.
  static const maxAfterAdShows = 3;

  final SharedPreferences _prefs;
  final PromoFetcher _fetch;
  final PromoLauncher _launch;
  final PromoEventLogger? _logEvent;

  PromoCampaign? _campaign;

  PromoService(
    this._prefs, {
    required PromoFetcher fetch,
    PromoLauncher? launch,
    PromoEventLogger? logEvent,
  })  : _fetch = fetch,
        _launch = launch ?? _launchExternal,
        _logEvent = logEvent;

  PromoCampaign? get campaign => _campaign;

  static Future<bool> _launchExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  String _key(String what) => 'promo_${what}_${_campaign!.package}';

  /// Uzak ayarı okur. Hata olursa tanıtım kapalı kalır.
  Future<void> load() async {
    try {
      _campaign = await _fetch();
    } catch (e) {
      debugPrint('Promo load failed: $e');
      _campaign = null;
    }
    notifyListeners();
  }

  bool get _opened => _campaign != null && (_prefs.getBool(_key('opened')) ?? false);

  /// Menü ikonundaki "yeni" noktası: kullanıcı menüyü açana kadar görünür.
  bool get showMenuDot =>
      _campaign != null && !(_prefs.getBool(_key('menu_seen')) ?? false);

  Future<void> markMenuSeen() async {
    if (!showMenuDot) return;
    await _prefs.setBool(_key('menu_seen'), true);
    notifyListeners();
  }

  /// Reklam sonrası kart: kullanıcı sayfayı açtıysa ya da kartı yeterince
  /// gördüyse bir daha çıkmaz.
  bool get shouldShowAfterAd =>
      _campaign != null &&
      !_opened &&
      (_prefs.getInt(_key('after_ad_shows')) ?? 0) < maxAfterAdShows;

  Future<void> markAfterAdShown() async {
    if (_campaign == null) return;
    final key = _key('after_ad_shows');
    await _prefs.setInt(key, (_prefs.getInt(key) ?? 0) + 1);
    _logEvent?.call('promo_shown', {'package': _campaign!.package});
  }

  /// Tanıtılan uygulamanın Play sayfasını açar. [source]: `after_ad` | `menu`.
  Future<void> open(String source) async {
    final campaign = _campaign;
    if (campaign == null) return;
    _logEvent?.call('promo_open', {'package': campaign.package, 'source': source});
    await _prefs.setBool(_key('opened'), true);
    try {
      await _launch(campaign.storeUri);
    } catch (e) {
      debugPrint('Promo launch failed: $e');
    }
  }
}
