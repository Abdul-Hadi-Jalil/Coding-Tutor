import 'package:coding_tutor/ads/ad_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdProvider with ChangeNotifier {
  // Ad State Management
  final Map<AdType, AdState> _adStates = {
    AdType.homeAd1: AdState(),
    AdType.homeAd2: AdState(),
    AdType.lensAd: AdState(),
    AdType.calendarAd: AdState(),
    AdType.myGardenAd: AdState(),
    AdType.discoverPlantAd: AdState(),
    AdType.discoverPlantDetailAd: AdState(),
    AdType.courseTopicsAd1: AdState(),
    AdType.courseTopicsAd2: AdState(),
    AdType.courseTopicsAd3: AdState(),
  };

  // Ad instances
  NativeAd? _homeAd1;
  NativeAd? _homeAd2;
  NativeAd? _calendarAd;
  NativeAd? _myGardenAd;
  NativeAd? _discoverPlantAd;
  NativeAd? _discoverPlantDetailAd;
  NativeAd? _courseTopicsAd1;
  NativeAd? _courseTopicsAd2;
  NativeAd? _courseTopicsAd3;
  RewardedAd? _lensAd; // Changed to RewardedAd

  // Retry and rate limiting
  final Map<AdType, DateTime?> _lastLoadAttempt = {};
  final Map<AdType, int> _retryCount = {};
  static const Duration _reloadDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;

  // Rewarded ad timing
  DateTime? _lastRewardedShow;
  static const Duration _minRewardedInterval = Duration(minutes: 2);

  // Analytics
  final Map<AdType, int> _loadAttempts = {};
  final Map<AdType, int> _loadSuccess = {};
  final Map<AdType, int> _loadFailures = {};

  // Getters for ad loaded states
  bool get isHomeAd1 => _adStates[AdType.homeAd1]!.isLoaded;
  bool get isHomeAd2 => _adStates[AdType.homeAd2]!.isLoaded;
  bool get isNotePageAd3 => _adStates[AdType.calendarAd]!.isLoaded;
  bool get isExercisePageAd1 => _adStates[AdType.myGardenAd]!.isLoaded;
  bool get isYVideoPageAd1 => _adStates[AdType.discoverPlantAd]!.isLoaded;
  bool get isYVideoPageAd2 => _adStates[AdType.discoverPlantDetailAd]!.isLoaded;
  bool get iscourseTopicsAd1 => _adStates[AdType.courseTopicsAd1]!.isLoaded;
  bool get iscourseTopicsAd2 => _adStates[AdType.courseTopicsAd2]!.isLoaded;
  bool get iscourseTopicsAd3 => _adStates[AdType.courseTopicsAd3]!.isLoaded;

  bool get isLensAd => _adStates[AdType.lensAd]!.isLoaded;

  // Getter for ad instances
  NativeAd? get homeAd1 => _homeAd1;
  NativeAd? get homeAd2 => _homeAd2;
  NativeAd? get calendarAd => _calendarAd;
  NativeAd? get myGardenAd => _myGardenAd;
  NativeAd? get discoverPlantAd => _discoverPlantAd;
  NativeAd? get discoverPlantDetailAd => _discoverPlantDetailAd;
  NativeAd? get courseTopicsAd1 => _courseTopicsAd1;
  NativeAd? get courseTopicsAd2 => _courseTopicsAd2;
  NativeAd? get courseTopicsAd3 => _courseTopicsAd3;

  RewardedAd? get lensAd => _lensAd;

  /// Preload ad agar already loaded nahi hai
  Future<void> preloadAd(AdType adType, {dynamic adSize}) async {
    final state = _adStates[adType];

    // Agar already loaded hai to skip karo
    if (state?.isLoaded == true) {
      print("ℹ️ ${adType.name} already loaded");
      return;
    }

    // Rate limiting: 30 seconds ke andar dobara load na karo
    final lastAttempt = _lastLoadAttempt[adType];
    if (lastAttempt != null &&
        DateTime.now().difference(lastAttempt) < _reloadDelay) {
      print("⏳ ${adType.name} rate limited, waiting...");
      return;
    }

    _lastLoadAttempt[adType] = DateTime.now();

    // Load appropriate ad type
    if (adType == AdType.lensAd) {
      await initializeRewardedAdWithRetry(adType);
    } else {
      await initializeNativeAdWithRetry(adType, adSize);
    }
  }

  /// Initialize rewarded ad with retry
  Future<void> initializeRewardedAdWithRetry(
    AdType adType, {
    int retryAttempt = 0,
  }) async {
    final adHelperId = _getAdHelperId(adType);
    if (adHelperId == null) return;

    _trackLoadAttempt(adType);
    print("🟡 Loading ${adType.name} Rewarded (Attempt ${retryAttempt + 1})");

    await RewardedAd.load(
      adUnitId: adHelperId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print("✅ ${adType.name} Rewarded Ad Loaded");
          _updateAdState(adType, true);
          _storeRewardedAd(adType, ad);
          _trackLoadSuccess(adType);
          _retryCount[adType] = 0;
        },
        onAdFailedToLoad: (error) {
          print("❌ ${adType.name} Rewarded Ad Failed: $error");
          _trackLoadFailure(adType);
          _updateAdState(adType, false);

          // Retry with exponential backoff
          if (retryAttempt < _maxRetries) {
            final delay = Duration(seconds: (retryAttempt + 1) * 5);
            print("🔄 Retrying ${adType.name} in ${delay.inSeconds}s");
            Future.delayed(delay, () {
              initializeRewardedAdWithRetry(
                adType,
                retryAttempt: retryAttempt + 1,
              );
            });
          }
        },
      ),
    );
  }

  /// Initialize native ad with retry
  Future<void> initializeNativeAdWithRetry(
    AdType adType,
    dynamic adSize, {
    int retryAttempt = 0,
  }) async {
    final adHelperId = _getAdHelperId(adType);
    if (adHelperId == null) return;

    _trackLoadAttempt(adType);
    print("🟡 Loading ${adType.name} Native Ad (Attempt ${retryAttempt + 1})");

    final nativeAd = NativeAd(
      adUnitId: adHelperId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print("✅ ${adType.name} Native Ad Loaded");
          _updateAdState(adType, true);
          _storeNativeAd(adType, ad as NativeAd);
          _trackLoadSuccess(adType);
          _retryCount[adType] = 0;
        },
        onAdFailedToLoad: (ad, error) {
          print("❌ ${adType.name} Native Ad Failed: $error");
          _trackLoadFailure(adType);
          ad.dispose();

          // Retry with exponential backoff
          if (retryAttempt < _maxRetries) {
            final delay = Duration(seconds: (retryAttempt + 1) * 5);
            print("🔄 Retrying ${adType.name} in ${delay.inSeconds}s");
            Future.delayed(delay, () {
              initializeNativeAdWithRetry(
                adType,
                adSize,
                retryAttempt: retryAttempt + 1,
              );
            });
          } else {
            _updateAdState(adType, false);
          }
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(templateType: adSize),
    );

    await nativeAd.load();
  }

  /// Legacy methods (keeping for backward compatibility)
  Future<void> initializeRewardedAd(AdType adType) async {
    await initializeRewardedAdWithRetry(adType);
  }

  Future<void> initializeNativeAd(AdType adType, adSize) async {
    await initializeNativeAdWithRetry(adType, adSize);
  }

  /// Check if rewarded can be shown
  bool canShowRewarded() {
    if (_lastRewardedShow == null) return true;

    return DateTime.now().difference(_lastRewardedShow!) > _minRewardedInterval;
  }

  /// Show rewarded ad with callback
  void showRewardedAd(AdType adType, {required Function() onRewarded}) {
    if (!canShowRewarded()) {
      print(
        "⏳ Too soon to show rewarded (wait ${_minRewardedInterval.inMinutes} min)",
      );
      return;
    }

    final adState = _adStates[adType];
    final rewardedAd = _getRewardedAd(adType);

    if (adState?.isLoaded != true || rewardedAd == null) {
      print("⚠️ ${adType.name} Rewarded Ad not ready");
      // Preload for next time
      initializeRewardedAdWithRetry(adType);
      return;
    }

    rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print("📺 ${adType.name} Rewarded Showing");
      },
      onAdDismissedFullScreenContent: (ad) {
        print("ℹ️ ${adType.name} Rewarded Closed");
        _lastRewardedShow = DateTime.now();
        ad.dispose();
        _updateAdState(adType, false);
        // Immediately load next ad
        Future.delayed(Duration(seconds: 1), () {
          initializeRewardedAdWithRetry(adType);
        });
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print("❌ ${adType.name} Rewarded Failed to Show: $error");
        ad.dispose();
        _updateAdState(adType, false);
        // Try loading again
        Future.delayed(Duration(seconds: 2), () {
          initializeRewardedAdWithRetry(adType);
        });
      },
    );

    rewardedAd.show(
      onUserEarnedReward: (ad, reward) {
        print("🎁 User earned reward: ${reward.amount} ${reward.type}");
        onRewarded(); // Call the callback when user earns reward
      },
    );
  }

  /// Refresh ad (dispose and reload)
  Future<void> refreshAd(AdType adType, {dynamic adSize}) async {
    print("🔄 Refreshing ${adType.name}");

    // Dispose old ad
    _disposeSpecificAd(adType);
    _updateAdState(adType, false);

    // Wait before reloading
    await Future.delayed(Duration(seconds: 2));

    // Reload
    await preloadAd(adType, adSize: adSize);
  }

  /// Dispose specific ad
  void _disposeSpecificAd(AdType adType) {
    switch (adType) {
      case AdType.homeAd1:
        _homeAd1?.dispose();
        _homeAd1 = null;
        break;
      case AdType.homeAd2:
        _homeAd2?.dispose();
        _homeAd2 = null;
        break;
      case AdType.calendarAd:
        _calendarAd?.dispose();
        _calendarAd = null;
        break;
      case AdType.myGardenAd:
        _myGardenAd?.dispose();
        _myGardenAd = null;
        break;
      case AdType.discoverPlantAd:
        _discoverPlantAd?.dispose();
        _discoverPlantAd = null;
        break;
      case AdType.discoverPlantDetailAd:
        _discoverPlantDetailAd?.dispose();
        _discoverPlantDetailAd = null;
        break;
      case AdType.lensAd:
        _lensAd?.dispose();
        _lensAd = null;
        break;
      case AdType.courseTopicsAd1:
        _courseTopicsAd1?.dispose();
        _courseTopicsAd1 = null;
      case AdType.courseTopicsAd2:
        _courseTopicsAd2?.dispose();
        _courseTopicsAd2 = null;
      case AdType.courseTopicsAd3:
        _courseTopicsAd3?.dispose();
        _courseTopicsAd3 = null;
    }
  }

  /// Dispose all ads
  void disposeAds() {
    _homeAd1?.dispose();
    _homeAd2?.dispose();
    _calendarAd?.dispose();
    _myGardenAd?.dispose();
    _discoverPlantAd?.dispose();
    _discoverPlantDetailAd?.dispose();
    _courseTopicsAd1?.dispose();
    _courseTopicsAd2?.dispose();
    _courseTopicsAd3?.dispose();
    _lensAd?.dispose();

    for (var state in _adStates.values) {
      state.isLoaded = false;
    }

    notifyListeners();
  }

  /// Get fill rate for an ad type
  double getFillRate(AdType adType) {
    final attempts = _loadAttempts[adType] ?? 0;
    final success = _loadSuccess[adType] ?? 0;

    if (attempts == 0) return 0.0;
    return success / attempts;
  }

  /// Print analytics
  void printAnalytics() {
    print("\n📊 ===== AD ANALYTICS =====");
    for (var adType in AdType.values) {
      final attempts = _loadAttempts[adType] ?? 0;
      final success = _loadSuccess[adType] ?? 0;
      final failures = _loadFailures[adType] ?? 0;
      final fillRate = getFillRate(adType);

      if (attempts > 0) {
        print(
          "${adType.name}: ${(fillRate * 100).toStringAsFixed(1)}% ($success/$attempts) | Failures: $failures",
        );
      }
    }
    print("========================\n");
  }

  // Helper methods
  void _updateAdState(AdType adType, bool isLoaded) {
    final state = _adStates[adType];
    if (state != null) {
      state.isLoaded = isLoaded;
      notifyListeners();
    }
  }

  void _trackLoadAttempt(AdType adType) {
    _loadAttempts[adType] = (_loadAttempts[adType] ?? 0) + 1;
  }

  void _trackLoadSuccess(AdType adType) {
    _loadSuccess[adType] = (_loadSuccess[adType] ?? 0) + 1;
  }

  void _trackLoadFailure(AdType adType) {
    _loadFailures[adType] = (_loadFailures[adType] ?? 0) + 1;
  }

  void _storeRewardedAd(AdType adType, RewardedAd ad) {
    switch (adType) {
      case AdType.lensAd:
        _lensAd = ad;
        break;
      default:
        ad.dispose();
        throw ArgumentError('Invalid ad type for rewarded ad');
    }
  }

  void _storeNativeAd(AdType adType, NativeAd ad) {
    switch (adType) {
      case AdType.homeAd1:
        _homeAd1 = ad;
        break;
      case AdType.homeAd2:
        _homeAd2 = ad;
        break;
      case AdType.calendarAd:
        _calendarAd = ad;
        break;
      case AdType.myGardenAd:
        _myGardenAd = ad;
        break;
      case AdType.discoverPlantAd:
        _discoverPlantAd = ad;
        break;
      case AdType.discoverPlantDetailAd:
        _discoverPlantDetailAd = ad;
        break;
      case AdType.courseTopicsAd1:
        _courseTopicsAd1 = ad;
        break;
      case AdType.courseTopicsAd2:
        _courseTopicsAd2 = ad;
        break;
      case AdType.courseTopicsAd3:
        _courseTopicsAd3 = ad;
        break;

      default:
        ad.dispose();
        throw ArgumentError('Invalid ad type for native ad');
    }
  }

  RewardedAd? _getRewardedAd(AdType adType) {
    switch (adType) {
      case AdType.lensAd:
        return _lensAd;
      default:
        return null;
    }
  }

  String? _getAdHelperId(AdType adType) {
    switch (adType) {
      case AdType.homeAd1:
        return AdHelper.homeAd1;
      case AdType.homeAd2:
        return AdHelper.homeAd2;
      case AdType.calendarAd:
        return AdHelper.calendarAd;
      case AdType.myGardenAd:
        return AdHelper.myGardenAd;
      case AdType.discoverPlantAd:
        return AdHelper.discoverPlantAd;
      case AdType.discoverPlantDetailAd:
        return AdHelper.discoverPlantDetailAd;
      case AdType.courseTopicsAd1:
        return AdHelper.courseTopicsAd1;
      case AdType.courseTopicsAd2:
        return AdHelper.courseTopicsAd2;
      case AdType.courseTopicsAd3:
        return AdHelper.courseTopicsAd3;
      case AdType.lensAd:
        return AdHelper.lensAd;
      default:
        return null;
    }
  }
}

class AdState {
  bool isLoaded = false;
}

enum AdType {
  homeAd1,
  homeAd2,
  calendarAd,
  myGardenAd,
  discoverPlantAd,
  discoverPlantDetailAd,
  courseTopicsAd1,
  courseTopicsAd2,
  courseTopicsAd3,
  lensAd,
}
