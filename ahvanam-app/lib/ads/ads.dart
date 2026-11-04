import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Full-screen (interstitial) ads with the "every second time" rule:
///   Preview:        1st no ad, 2nd ad, 3rd no ad, 4th ad …
///   Save to phone:  1st no ad, 2nd ad, 3rd no ad, 4th ad …
/// The two counters are separate. One interstitial is always kept loaded,
/// so it shows instantly; if none is ready, the action simply continues.
class Ads {
  Ads._();

  /// `flutter run --dart-define=NO_ADS=true` hides every ad (clean promo screenshots).
  static const _noAds = bool.fromEnvironment('NO_ADS');

  static bool get supported => !_noAds && !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static InterstitialAd? _interstitial;
  static bool _loading = false;
  static int _previewCount = 0;
  static int _saveCount = 0;

  static Future<void> init() async {
    if (!supported) return;
    try {
      await MobileAds.instance.initialize();
      _loadInterstitial();
    } catch (e) {
      debugPrint('Ads.init failed: $e');
    }
  }

  static void _loadInterstitial() {
    if (!supported || _loading || _interstitial != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Interstitial failed to load: $error');
          // Try again a bit later (no network, no fill…).
          Timer(const Duration(seconds: 30), _loadInterstitial);
        },
      ),
    );
  }

  /// Call before opening the preview. Completes when the ad (if any) is closed.
  static Future<void> beforePreview() => _maybeShow(++_previewCount);

  /// Call before saving cards to the phone's gallery.
  static Future<void> beforeSave() => _maybeShow(++_saveCount);

  static Future<void> _maybeShow(int count) async {
    if (!supported || count.isOdd) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    final done = Completer<void>();
    void finish(InterstitialAd a) {
      a.dispose();
      _loadInterstitial();
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (a, _) => finish(a),
    );
    await ad.show();
    return done.future;
  }
}
