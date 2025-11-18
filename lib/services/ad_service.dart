import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AdService {
  static InterstitialAd? _interstitialAd;
  static BannerAd? bannerAd;

  static Future<void> init() async {
    print("loading ads");
    await MobileAds.instance.initialize();

    _loadInterstitial();
    _loadBanner();
  }



  static void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3774337907915828/2528660957", // TODO replace
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (err) {
          debugPrint("⚠️ Failed to load interstitial ad: $err");
          _interstitialAd = null;
        },
      ),
    );
  }

  static void _loadBanner() {
    print("loading banner ad");
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: "ca-app-pub-3774337907915828/1061049500", // TODO replace
      listener: const BannerAdListener(),
      request: const AdRequest(),
    )..load();
  }


  static BannerAd? createBannerAd() {

    try {
      return BannerAd(
        size: AdSize.banner,
        adUnitId: "ca-app-pub-3774337907915828/1061049500",
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) => print('Banner ad loaded.'),
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('Banner ad failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
      )..load();
    } catch (e) {
      print("Error creating banner ad: $e");
      return null;
    }
  }

  static void disposeBannerAd() {
    bannerAd?.dispose();
    bannerAd = null;
  }

  static Future<void> showInterstitialAndNavigate(
      BuildContext context,
      Widget targetScreen,
      ) async {


    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad){
          ad.dispose();
          _loadInterstitial();
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
          // Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
        },
      );
      _interstitialAd!.show();
    } else {
      // ✅ Silent fallback → log only, no message to user
      debugPrint("ℹ️ Interstitial ad not ready. Navigating without showing ad.");
      Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
    }
  }

  /// ✅ Rewarded Ads → +5 credits AFTER ad is closed
  static Future<void> showRewardedAd(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool rewardEarned = false; // track reward

    RewardedAd.load(
      adUnitId: "ca-app-pub-3774337907915828/4113205367", // TODO replace
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async {
              ad.dispose();

              if (rewardEarned) {
                try {
                  final userDoc =
                  FirebaseFirestore.instance.collection("users").doc(user.uid);

                  await FirebaseFirestore.instance.runTransaction((tx) async {
                    final snap = await tx.get(userDoc);
                    final currentCredits = (snap.data()?['credits'] ?? 0) as int;
                    tx.update(userDoc, {'credits': currentCredits + 5});
                  });
                  print('credits added');

                  // ✅ Show Lottie only after ad is closed and reward was earned
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 👈 keeps content centered tightly
                        children: [
                          Lottie.asset(
                            'assets/success.json',
                            repeat: false,
                            onLoaded: (comp) {
                              Future.delayed(comp.duration, () {
                                Navigator.of(context).pop();
                              });
                            },
                          ),
                          const SizedBox(height: 16), // spacing between animation and text
                          const Text(
                            "Credits Added 🎉",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                decoration: TextDecoration.none
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

                } catch (e) {
                  debugPrint("Error updating credits: $e");
                }
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );

          ad.show(
            onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
              rewardEarned = true; // ✅ mark reward as earned
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint("⚠️ Failed to load rewarded ad: $error");
          // ✅ Show message if no rewarded ad
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No rewarded ad available. Please try again later.")),
          );
        },
      ),
    );
  }
}
