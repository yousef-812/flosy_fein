import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _currencies = [
    {'code': 'ج.م', 'key': 'currency_egp'},
    {'code': 'ر.س', 'key': 'currency_sar'},
    {'code': 'د.إ', 'key': 'currency_aed'},
    {'code': 'د.ك', 'key': 'currency_kwd'},
    {'code': 'د.أ', 'key': 'currency_jod'},
    {'code': 'ج.س', 'key': 'currency_sdg'},
    {'code': 'دولار', 'key': 'currency_usd'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish(BuildContext context) async {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final transProvider = Provider.of<TransactionProvider>(context, listen: false);

    // Apply settings immediately
    await themeProvider.toggleTheme(onboarding.isDarkMode);
    await transProvider.setPreferredCurrency(onboarding.selectedCurrency);
    await onboarding.completeOnboarding();

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'onboarding_complete',
        parameters: {
          'currency': onboarding.selectedCurrency,
          'theme_mode': onboarding.isDarkMode ? 'dark' : 'light',
          'goal': onboarding.selectedGoal,
        },
      );
    } catch (e) {
      debugPrint('Firebase Analytics error: $e');
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = Provider.of<OnboardingProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final List<Map<String, String>> goals = [
      {
        'title': languageProvider.translate('onboarding_goal1_title'),
        'desc': languageProvider.translate('onboarding_goal1_desc'),
      },
      {
        'title': languageProvider.translate('onboarding_goal2_title'),
        'desc': languageProvider.translate('onboarding_goal2_desc'),
      },
      {
        'title': languageProvider.translate('onboarding_goal3_title'),
        'desc': languageProvider.translate('onboarding_goal3_desc'),
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider
                        .translate('onboarding_step_progress_4')
                        .replaceFirst('{}', '${_currentPage + 1}'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(left: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF1E88E5)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Onboarding Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    languageProvider.translate('onboarding_welcome'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    languageProvider.translate('onboarding_welcome_sub_4'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Page View Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  // Page 0: Language Selection
                  _buildPage(
                    title: languageProvider.translate('onboarding_language_title'),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          // Arabic Language Option
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: languageProvider.isArabic,
                              label: languageProvider.translate('onboarding_arabic'),
                              child: InkWell(
                                onTap: () => languageProvider.changeLanguage('ar'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: languageProvider.isArabic
                                        ? const Color(0xFF1E88E5).withOpacity(0.15)
                                        : Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: languageProvider.isArabic
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey.withOpacity(0.3),
                                      width: languageProvider.isArabic ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🇸🇦', style: TextStyle(fontSize: 48)),
                                      const SizedBox(height: 12),
                                      Text(
                                        languageProvider.translate('onboarding_arabic'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // English Language Option
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: !languageProvider.isArabic,
                              label: languageProvider.translate('onboarding_english'),
                              child: InkWell(
                                onTap: () => languageProvider.changeLanguage('en'),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: !languageProvider.isArabic
                                        ? const Color(0xFF1E88E5).withOpacity(0.15)
                                        : Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: !languageProvider.isArabic
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey.withOpacity(0.3),
                                      width: !languageProvider.isArabic ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('🇬🇧', style: TextStyle(fontSize: 48)),
                                      const SizedBox(height: 12),
                                      Text(
                                        languageProvider.translate('onboarding_english'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Page 1: Currency Selection
                  _buildPage(
                    title: languageProvider.translate('onboarding_currency_title'),
                    content: GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(24.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemCount: _currencies.length,
                      itemBuilder: (context, index) {
                        final curr = _currencies[index];
                        final code = curr['code']!;
                        final isSelected = onboarding.selectedCurrency == code;
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: languageProvider.translate(curr['key']!),
                          child: InkWell(
                            onTap: () => onboarding.setCurrency(code),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 48), // Accessibility Target minimum
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E88E5).withOpacity(0.15)
                                    : Theme.of(context).cardColor,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E88E5)
                                      : Colors.grey.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                languageProvider.translate(curr['key']!),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1E88E5)
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page 2: Theme Selection
                  _buildPage(
                    title: languageProvider.translate('onboarding_theme_title'),
                    content: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          // Light Theme Option
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: !onboarding.isDarkMode,
                              label: languageProvider.translate('onboarding_light_mode'),
                              child: InkWell(
                                onTap: () => onboarding.setThemeMode(false),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: !onboarding.isDarkMode
                                        ? const Color(0xFFC5A059).withOpacity(0.15)
                                        : Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: !onboarding.isDarkMode
                                          ? const Color(0xFFC5A059)
                                          : Colors.grey.withOpacity(0.3),
                                      width: !onboarding.isDarkMode ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.light_mode, size: 48, color: Colors.orange),
                                      const SizedBox(height: 12),
                                      Text(
                                        languageProvider.translate('onboarding_light_mode'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Dark Theme Option
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: onboarding.isDarkMode,
                              label: languageProvider.translate('onboarding_dark_mode'),
                              child: InkWell(
                                onTap: () => onboarding.setThemeMode(true),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: onboarding.isDarkMode
                                        ? const Color(0xFF1E88E5).withOpacity(0.15)
                                        : Theme.of(context).cardColor,
                                    border: Border.all(
                                      color: onboarding.isDarkMode
                                          ? const Color(0xFF1E88E5)
                                          : Colors.grey.withOpacity(0.3),
                                      width: onboarding.isDarkMode ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.dark_mode, size: 48, color: Color(0xFF1E88E5)),
                                      const SizedBox(height: 12),
                                      Text(
                                        languageProvider.translate('onboarding_dark_mode'),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Page 3: Goal Selection
                  _buildPage(
                    title: languageProvider.translate('onboarding_goal_title'),
                    content: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: goals.length,
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final isSelected = onboarding.selectedGoal == goal['title'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Semantics(
                            button: true,
                            selected: isSelected,
                            label: "${goal['title']}: ${goal['desc']}",
                            child: InkWell(
                              onTap: () => onboarding.setGoal(goal['title']!),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1E88E5).withOpacity(0.15)
                                      : Theme.of(context).cardColor,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF1E88E5)
                                        : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? const Color(0xFF1E88E5) : Colors.grey,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            goal['title']!,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            goal['desc']!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    Semantics(
                      button: true,
                      label: languageProvider.translate('previous'),
                      child: TextButton(
                        onPressed: _previousPage,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(80, 48), // Accessibility Minimum
                        ),
                        child: Text(
                          languageProvider.translate('previous'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Semantics(
                    button: true,
                    label: _currentPage == 3
                        ? languageProvider.translate('start_using')
                        : languageProvider.translate('next'),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 3) {
                          _nextPage();
                        } else {
                          _finish(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(140, 48), // Accessibility Minimum 48dp
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == 3
                            ? languageProvider.translate('start_using')
                            : languageProvider.translate('next'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(child: content),
      ],
    );
  }
}
