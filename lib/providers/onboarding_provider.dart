import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  bool _isOnboarded = false;
  String _selectedGoal = 'أوفر فلوس';
  String _selectedCurrency = 'ج.م';
  bool _isDarkMode = true;

  OnboardingProvider() {
    _loadOnboardingStatus();
  }

  bool get isOnboarded => _isOnboarded;
  String get selectedGoal => _selectedGoal;
  String get selectedCurrency => _selectedCurrency;
  bool get isDarkMode => _isDarkMode;

  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('is_onboarded') ?? false;
    _selectedGoal = prefs.getString('user_goal') ?? 'أوفر فلوس';
    _selectedCurrency = prefs.getString('preferred_currency') ?? 'ج.م';
    _isDarkMode = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  void setGoal(String goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  void setCurrency(String currency) {
    _selectedCurrency = currency;
    notifyListeners();
  }

  void setThemeMode(bool dark) {
    _isDarkMode = dark;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    await prefs.setString('user_goal', _selectedGoal);
    await prefs.setString('preferred_currency', _selectedCurrency);
    await prefs.setBool('is_dark_mode', _isDarkMode);
    _isOnboarded = true;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', false);
    _isOnboarded = false;
    notifyListeners();
  }
}
