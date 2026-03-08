// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdsMode {
  production, // اعلانات حقيقية
  test, // اعلانات تيست
  disabled, // بدون اعلانات
}

class AdsManager {
  static final AdsManager _instance = AdsManager._internal();
  static AdsManager get instance => _instance;

  AdsManager._internal();

  // ==============================
  // 🔥 تحكم كامل في وضع الإعلانات
  // ==============================
  AdsMode _adsMode = AdsMode.production;

  void setAdsMode(AdsMode mode) {
    _adsMode = mode;
    print("Ads Mode Changed To: $_adsMode");
  }

  bool get isAdsEnabled => _adsMode != AdsMode.disabled;

  // ==============================
  // Android Only
  // ==============================
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // ==============================
  // Real Production IDs
  // ==============================
  final String _realAppOpenId = "ca-app-pub-8060882974662761/5597743624";

  final String _realBannerId = "ca-app-pub-8060882974662761/7246013008";

  final String _realRewardedId = "ca-app-pub-8060882974662761/3589334448";

  // ==============================
  // Google Test IDs
  // ==============================
  final String _testAppOpenId = "ca-app-pub-3940256099942544/9257395921";

  final String _testBannerId = "ca-app-pub-3940256099942544/6300978111";

  final String _testRewardedId = "ca-app-pub-3940256099942544/5224354917";

  String get appOpenId =>
      _adsMode == AdsMode.test ? _testAppOpenId : _realAppOpenId;

  String get bannerId =>
      _adsMode == AdsMode.test ? _testBannerId : _realBannerId;

  String get rewardedId =>
      _adsMode == AdsMode.test ? _testRewardedId : _realRewardedId;

  AppOpenAd? _appOpenAd;
  RewardedAd? _rewardedAd;

  bool _isShowingAd = false;

  // ==============================
  // Initialize
  // ==============================
  Future<void> initialize() async {
    if (!_isAndroid || !isAdsEnabled) return;

    try {
      await MobileAds.instance.initialize();
      loadAppOpenAd();
      loadRewardedAd();
    } catch (e) {
      print("Ads Init Error: $e");
    }
  }

  // ==============================
  // App Open
  // ==============================
  void loadAppOpenAd() {
    if (!isAdsEnabled || !_isAndroid) return;

    AppOpenAd.load(
      adUnitId: appOpenId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          print("AppOpen Failed: $error");
        },
      ),
    );
  }

  void showAppOpenAd() {
    if (!isAdsEnabled || !_isAndroid || _appOpenAd == null || _isShowingAd) {
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  // ==============================
  // Rewarded
  // ==============================
  void loadRewardedAd() {
    if (!isAdsEnabled || !_isAndroid) return;

    RewardedAd.load(
      adUnitId: rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          // print("Rewarded Failed: $error");
        },
      ),
    );
  }

  void showRewardedAd({required void Function() onAdFinished}) {
    if (!isAdsEnabled || !_isAndroid || _rewardedAd == null) {
      onAdFinished();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
        onAdFinished(); // Proceed when dismissed
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
        onAdFinished(); // Proceed even if it fails
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // We handle navigation in dismissal to avoid overlap,
        // but if we want instant transition, we can do it here.
        // Using dismiss is safer for navigation.
      },
    );

    _rewardedAd = null;
  }
}
