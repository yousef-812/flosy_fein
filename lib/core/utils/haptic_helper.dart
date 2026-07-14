import 'package:flutter/services.dart';

class HapticHelper {
  static Future<void> lightTap() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> mediumTap() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavyTap() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> successTap() async {
    await HapticFeedback.vibrate();
  }
}
