import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdHelper {
  // Premium is intentionally disabled until real store billing is integrated.
  static bool isPremiumUser = false;
  static DateTime? _lastInterstitialShowTime;

  static Future<void> checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove the old mock flag so a tap on the previous demo button cannot
    // permanently unlock premium features without a verified purchase.
    await prefs.remove('is_premium_user');
    isPremiumUser = false;
  }

  /// Premium must only be changed by a verified billing implementation.
  /// Passing `true` is ignored until Google Play / App Store billing is added.
  static Future<void> setPremiumStatus(bool premium) async {
    final prefs = await SharedPreferences.getInstance();
    if (premium) {
      debugPrint('Premium activation ignored: store billing is not configured.');
      return;
    }

    await prefs.remove('is_premium_user');
    isPremiumUser = false;
  }

  // Interstitial frequency capping (at most once every 3 minutes).
  static bool get canShowInterstitial {
    if (isPremiumUser) return false;
    if (_lastInterstitialShowTime == null) return true;
    final difference = DateTime.now().difference(_lastInterstitialShowTime!);
    return difference.inMinutes >= 3;
  }

  static void recordInterstitialShown() {
    _lastInterstitialShowTime = DateTime.now();
  }

  // Google-provided test ad unit IDs only. Replace these values after the app
  // is created in AdMob and production consent/release checks are complete.
  static String get bannerAdUnitId {
    if (isPremiumUser || kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (isPremiumUser || kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (isPremiumUser || kIsWeb) return '';
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986694507';
    }
    return '';
  }
}
