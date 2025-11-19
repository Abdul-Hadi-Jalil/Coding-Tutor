import 'dart:io';
import 'package:flutter/foundation.dart';

class AdHelper {
  // Android ad unit IDs
  static const Map<String, String> _androidAds = {
    'homeAd1': 'ca-app-pub-3774337907915828/4814707974', // native ad
    'homeAd2': 'ca-app-pub-3774337907915828/8737926520', // native ad
    'lensAd': 'ca-app-pub-3774337907915828/2301769861', //  REWARDED ad unit
    'calendarAd': 'ca-app-pub-3774337907915828/3485599848', // native ad
    'myGardenAd': 'ca-app-pub-3774337907915828/3266656738', // native ad
    'discoverPlantAd': 'ca-app-pub-3774337907915828/9605544817', // native ad
    'discoverPlantDetailAd':
        'ca-app-pub-9286190198569219/5595831514', // native ad
    'courseTopicsAd1': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
    'courseTopicsAd2': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
    'courseTopicsAd3': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
  };

  // iOS ad unit IDs
  static const Map<String, String> _iosAds = {
    'homeAd1': 'ca-app-pub-3774337907915828/4814707974', // native ad
    'homeAd2': 'ca-app-pub-3774337907915828/8737926520', // native ad
    'lensAd': 'ca-app-pub-3774337907915828/2301769861', // REWARDED ad unit
    'calendarAd': 'ca-app-pub-3774337907915828/3485599848', // native ad
    'myGardenAd': 'ca-app-pub-3774337907915828/3266656738', // native ad
    'discoverPlantAd': 'ca-app-pub-3774337907915828/9605544817', // native ad
    'discoverPlantDetailAd':
        'ca-app-pub-9286190198569219/5595831514', // native ad
    'courseTopicsAd1': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
    'courseTopicsAd2': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
    'courseTopicsAd3': 'ca-app-pub-XXXXXXXXXXXXXXX/XXXXXXXXXX', // native ad
  };

  // Test ad unit IDs
  static const Map<String, String> _testAds = {
    'native': 'ca-app-pub-3940256099942544/2247696110',
    'rewarded':
        'ca-app-pub-3940256099942544/5224354917', // Test Rewarded Ad Android
    'banner': 'ca-app-pub-3940256099942544/6300978111',
    'nativeIOS': 'ca-app-pub-3940256099942544/3986624511',
    'rewardedIOS':
        'ca-app-pub-3940256099942544/1712485313', // Test Rewarded Ad iOS
  };

  /// Check if we should use test ads
  static bool get useTestAds {
    // Use test ads in debug mode
    return kDebugMode;
  }

  static String _getAd(String adName, {bool isRewarded = false}) {
    // Test mode: return test ads
    if (useTestAds) {
      if (Platform.isAndroid) {
        return isRewarded ? _testAds['rewarded']! : _testAds['native']!;
      } else if (Platform.isIOS) {
        return isRewarded ? _testAds['rewardedIOS']! : _testAds['nativeIOS']!;
      }
    }

    // Production mode: return real ads
    if (Platform.isAndroid) {
      final adId = _androidAds[adName];
      if (adId == null || adId.contains('XXXXXXX')) {
        // Fallback to test ad if real ID not configured
        print(
          "⚠️ Warning: Real ad ID not configured for $adName, using test ad",
        );
        return isRewarded ? _testAds['rewarded']! : _testAds['native']!;
      }
      return adId;
    } else if (Platform.isIOS) {
      final adId = _iosAds[adName];
      if (adId == null || adId.contains('XXXXXXX')) {
        print(
          "⚠️ Warning: Real ad ID not configured for $adName, using test ad",
        );
        return isRewarded ? _testAds['rewardedIOS']! : _testAds['nativeIOS']!;
      }
      return adId;
    }

    throw UnsupportedError('Unsupported platform');
  }

  // Ad getters
  static String get homeAd1 => _getAd('homeAd1');
  static String get homeAd2 => _getAd('homeAd2');
  static String get lensAd =>
      _getAd('lensAd', isRewarded: true); // ✅ FIXED: Added isRewarded flag
  static String get calendarAd => _getAd('calendarAd');
  static String get myGardenAd => _getAd('myGardenAd');
  static String get discoverPlantAd => _getAd('discoverPlantAd');
  static String get discoverPlantDetailAd => _getAd('discoverPlantDetailAd');
  static String get courseTopicsAd1 => _getAd('courseTopicsAd1');
  static String get courseTopicsAd2 => _getAd('courseTopicsAd2');
  static String get courseTopicsAd3 => _getAd('courseTopicsAd3');
}
