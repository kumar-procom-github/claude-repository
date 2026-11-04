import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob IDs for "Ahvanam: Invitation Maker" (Vums Labs).
///
/// Release builds (Play Store / release APK) use the REAL ids.
/// Debug builds (`flutter run`) use Google's TEST ids, so testing on your
/// own phone never shows or clicks your real ads — clicking your own real
/// ads can get the AdMob account suspended.
///
/// The App ID is set in android/app/src/main/AndroidManifest.xml.
class AdIds {
  AdIds._();

  // ---- Real ids (Android) --------------------------------------------------
  static const _banner = 'ca-app-pub-8051715352208110/4338015382';
  static const _interstitial = 'ca-app-pub-8051715352208110/8085688706';

  // ---- Google test ids -----------------------------------------------------
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  // iOS has no real ad units yet (Android-only release), so it always uses test ids.
  static String get banner => Platform.isIOS
      ? _testBannerIos
      : (kReleaseMode ? _banner : _testBannerAndroid);

  static String get interstitial => Platform.isIOS
      ? _testInterstitialIos
      : (kReleaseMode ? _interstitial : _testInterstitialAndroid);
}
