import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  BannerAd? bannerAd;

  void loadBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          onAdFailedToLoad(error);
          ad.dispose();
        },
      ),
    )..load();
  }

  void dispose() {
    bannerAd?.dispose();
  }
}
