import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'ar';
  Map<String, String> _localizedStrings = {};

  String get currentLanguage => _currentLanguage;
  bool get isArabic => _currentLanguage == 'ar';

  /// Initialize language and load translations from external JSON files
  Future<void> init() async {
    await _loadLanguage();
    await _loadTranslations();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user has previously set language
    final savedLang = prefs.getString('app_language');
    if (savedLang != null) {
      _currentLanguage = savedLang;
    } else {
      // Auto-detect system language
      try {
        final systemLocale = Platform.localeName.toLowerCase();
        if (systemLocale.startsWith('en')) {
          _currentLanguage = 'en';
        } else {
          _currentLanguage = 'ar';
        }
      } catch (_) {
        _currentLanguage = 'ar';
      }
    }
  }

  Future<void> _loadTranslations() async {
    try {
      final jsonString = await rootBundle.loadString('assets/lang/$_currentLanguage.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint("Error loading translations for $_currentLanguage: $e");
      // Fallback/Stub in case asset is not loaded yet (e.g. during tests or initial layout)
      _localizedStrings = {};
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (langCode != 'ar' && langCode != 'en') return;
    _currentLanguage = langCode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    
    await _loadTranslations();
    notifyListeners();
  }

  /// Translation lookups
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}
