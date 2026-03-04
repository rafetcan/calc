class AdService {
  Future<void> loadRewardedAd() async {}

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    required void Function(String) onError,
  }) async {
    onError('Ads not supported on this platform');
    return false;
  }
}
