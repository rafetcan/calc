class AdService {
  bool get isReady => false;

  bool get isLoading => false;

  Future<bool> loadRewardedAd() async => false;

  Future<bool> showRewardedAd({
    required void Function() onRewarded,
    required void Function(String) onError,
    void Function()? onDismissed,
  }) async {
    onError('Ads not supported on this platform');
    return false;
  }
}
