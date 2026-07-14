import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamificationProvider extends ChangeNotifier {
  int _userCoins = 0;
  String _lastCheckInDate = '';
  List<String> _unlockedThemes = ['theme_default'];
  String _activeTheme = 'theme_default';

  GamificationProvider() {
    _loadGamificationData();
  }

  int get userCoins => _userCoins;
  List<String> get unlockedThemes => _unlockedThemes;
  String get activeTheme => _activeTheme;

  bool get canCheckInToday {
    final todayStr = _getTodayString();
    return _lastCheckInDate != todayStr;
  }

  Future<void> _loadGamificationData() async {
    final prefs = await SharedPreferences.getInstance();
    _userCoins = prefs.getInt('user_coins') ?? 0;
    _lastCheckInDate = prefs.getString('last_check_in_date') ?? '';
    _unlockedThemes = prefs.getStringList('unlocked_themes') ?? ['theme_default'];
    _activeTheme = prefs.getString('active_theme') ?? 'theme_default';
    notifyListeners();
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<bool> claimDailyCheckIn() async {
    if (!canCheckInToday) return false;

    final todayStr = _getTodayString();
    _userCoins += 10; // 10 coins reward
    _lastCheckInDate = todayStr;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', _userCoins);
    await prefs.setString('last_check_in_date', _lastCheckInDate);
    
    notifyListeners();
    return true;
  }

  Future<void> addCoins(int amount) async {
    _userCoins += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', _userCoins);
    notifyListeners();
  }

  Future<bool> buyTheme(String themeId, int price) async {
    if (_userCoins < price || _unlockedThemes.contains(themeId)) {
      return false;
    }

    _userCoins -= price;
    _unlockedThemes.add(themeId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', _userCoins);
    await prefs.setStringList('unlocked_themes', _unlockedThemes);

    notifyListeners();
    return true;
  }

  Future<void> setActiveTheme(String themeId) async {
    if (!_unlockedThemes.contains(themeId)) return;
    _activeTheme = themeId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_theme', themeId);
    notifyListeners();
  }

  Future<void> resetCoins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_coins', 0);
    await prefs.setString('last_check_in_date', '');
    await prefs.setStringList('unlocked_themes', ['theme_default']);
    await prefs.setString('active_theme', 'theme_default');
    _userCoins = 0;
    _lastCheckInDate = '';
    _unlockedThemes = ['theme_default'];
    _activeTheme = 'theme_default';
    notifyListeners();
  }
}
