import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'promo_service.dart';

/// Firebase projesi (`feedback-appss`) diğer uygulamalarla paylaşıldığı için
/// anahtarlar `calc_` ile başlar.
const _enabledKey = 'calc_promo_enabled';
const _packageKey = 'calc_promo_package';
const _nameKey = 'calc_promo_name';

/// Tanıtım ayarını Remote Config'den okur. Konsolda değer yoksa varsayılanlar
/// geçerlidir ve tanıtım kapalıdır.
Future<PromoCampaign?> fetchPromoFromRemoteConfig() async {
  // Yalnızca debug: konsola dokunmadan denemek için
  // --dart-define=PROMO_TEST_PACKAGE=... --dart-define=PROMO_TEST_NAME=...
  const testPackage = String.fromEnvironment('PROMO_TEST_PACKAGE');
  if (kDebugMode && testPackage.isNotEmpty) {
    return PromoCampaign.fromValues(
      enabled: true,
      package: testPackage,
      name: const String.fromEnvironment('PROMO_TEST_NAME'),
    );
  }

  final rc = FirebaseRemoteConfig.instance;
  await rc.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval:
        kDebugMode ? Duration.zero : const Duration(hours: 6),
  ));
  await rc.setDefaults(const {
    _enabledKey: false,
    _packageKey: '',
    _nameKey: '',
  });
  try {
    await rc.fetchAndActivate();
  } catch (e) {
    // Ağ yoksa son etkin (ya da varsayılan) değerlerle devam et.
    debugPrint('Remote Config fetch failed: $e');
  }
  return PromoCampaign.fromValues(
    enabled: rc.getBool(_enabledKey),
    package: rc.getString(_packageKey),
    name: rc.getString(_nameKey),
  );
}
