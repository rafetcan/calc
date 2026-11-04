import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ödüllü reklam. Uygulama açılışında yüklenmez; kullanıcı reklam istediğinde
/// yüklenir (açılışta yüklenen reklamların ~%99'u hiç gösterilmiyordu).
/// İzlenen reklamın ardından bir sonraki önceden yüklenir.
class AdService {
  /// Google'a göre yüklenen ödüllü reklam ~1 saat sonra geçersiz olur.
  static const _adLifetime = Duration(minutes: 55);

  RewardedAd? _rewardedAd;
  DateTime? _loadedAt;
  Completer<bool>? _loading;

  bool get isReady =>
      _rewardedAd != null &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < _adLifetime;

  bool get isLoading => _loading != null;

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4634689499659793/1731776532'; // support_rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID - iOS için AdMob'dan alın
    }
    return '';
  }

  /// Reklam hazırsa ya da yükleniyorsa yeni istek atmaz. Yükleme bitince
  /// başarılıysa `true` döner.
  Future<bool> loadRewardedAd() {
    if (isReady) return Future.value(true);
    if (_loading != null) return _loading!.future;
    if (_rewardedAdUnitId.isEmpty) return Future.value(false);

    // Süresi dolmuş reklamı at.
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _loadedAt = null;

    final completer = Completer<bool>();
    _loading = completer;

    void finish(bool loaded) {
      _loading = null;
      if (!completer.isCompleted) completer.complete(loaded);
    }

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _loadedAt = DateTime.now();
          finish(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          finish(false);
        },
      ),
    ).catchError((Object _) => finish(false));

    return completer.future;
  }

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    required void Function(String) onError,
  }) async {
    if (!isReady) {
      onError('Ad not ready');
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    _loadedAt = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        // İzleyen kullanıcı yine izleyebilir: bir sonrakini hazırla.
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        onError(error.message);
      },
    );

    await ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onRewarded();
    });
    return true;
  }
}
