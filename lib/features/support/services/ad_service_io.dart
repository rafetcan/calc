import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  static String get _rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-4634689499659793/1731776532'; // support_rewarded
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID - iOS için AdMob'dan alın
    }
    return '';
  }

  Future<void> loadRewardedAd() async {
    if (_rewardedAdUnitId.isEmpty) return;

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isAdLoaded = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    required void Function(String) onError,
  }) async {
    if (!_isAdLoaded || _rewardedAd == null) {
      onError('Ad not ready');
      await loadRewardedAd();
      return false;
    }

    final ad = _rewardedAd!;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        onError(error.message);
      },
    );

    await ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onRewarded();
    });
    return true;
  }
}
