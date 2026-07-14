import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdHelper {
  // Premium subscription check
  static bool isPremiumUser = false;
  static DateTime? _lastInterstitialShowTime;

  static Future<void> checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isPremiumUser = prefs.getBool('is_premium_user') ?? false;
  }

  static Future<void> setPremiumStatus(bool premium) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', premium);
    isPremiumUser = premium;
  }

  // Interstitial frequency capping (at most once every 3 minutes for better user experience)
  static bool get canShowInterstitial {
    if (isPremiumUser) return false;
    if (_lastInterstitialShowTime == null) return true;
    final difference = DateTime.now().difference(_lastInterstitialShowTime!);
    return difference.inMinutes >= 3;
  }

  static void recordInterstitialShown() {
    _lastInterstitialShowTime = DateTime.now();
  }

  // Ad Unit IDs
  static String get bannerAdUnitId {
    if (isPremiumUser) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android Test Banner
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS Test Banner
      }
    }
    // Production Banner ID
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-4624889874966809/6394107823';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (isPremiumUser) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712'; // Android Test Interstitial
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910'; // iOS Test Interstitial
      }
    }
    // Production Interstitial ID
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-4624889874966809/1109991553';
    }
    return '';
  }

  static String get nativeAdUnitId {
    if (isPremiumUser) return '';
    if (kDebugMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/2247696110'; // Android Test Native
      } else if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/3986694507'; // iOS Test Native
      }
    }
    // Production Native ID
    if (Platform.isAndroid || Platform.isIOS) {
      return 'ca-app-pub-4624889874966809/1718852877';
    }
    return '';
  }
}
