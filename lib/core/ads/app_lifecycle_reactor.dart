import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ads_manager.dart';

class AppLifecycleReactor {
  final AdsManager adsManager;

  AppLifecycleReactor({required this.adsManager});

  void listenToAppStateChanges() {
    AppStateEventNotifier.startListening();

    AppStateEventNotifier.appStateStream.listen((state) {
      if (state == AppState.foreground && AdsManager.instance.isAdsEnabled) {
        adsManager.showAppOpenAd();
      }
    });
  }
}
