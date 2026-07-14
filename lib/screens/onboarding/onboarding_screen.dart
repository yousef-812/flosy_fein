import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _currencies = ['ج.م', 'ر.س', 'د.إ', 'د.ك', 'د.أ', 'ج.س', 'دولار'];
  final List<Map<String, String>> _goals = [
    {'title': 'أوفر فلوس', 'desc': 'تقليل المصاريف الزائدة والادخار للمستقبل.'},
    {'title': 'أعرف مصاريفي', 'desc': 'تتبع أين تذهب أموالك كل شهر بالتفصيل.'},
    {'title': 'أتابع ميزانية', 'desc': 'وضع حد أقصى للمصاريف لتفادي الديون.'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
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
                    'الخطوة ${_currentPage + 1} من 3',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: List.generate(3, (index) {
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'أهلاً بك في فلوسي فين 👋',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'هنسألك 3 أسئلة سريعة عشان نضبط التطبيق ليك.',
                    style: TextStyle(
                      fontFamily: 'Amiri',
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
                  // Page 1: Currency Selection
                  _buildPage(
                    title: 'ما هي عملتك المفضلة؟',
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
                        final isSelected = onboarding.selectedCurrency == curr;
                        return InkWell(
                          onTap: () => onboarding.setCurrency(curr),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
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
                              curr,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFF1E88E5)
                                    : Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page 2: Theme Selection
                  _buildPage(
                    title: 'بتفضل مظهر التطبيق إيه؟',
                    content: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          // Light Theme Option
                          Expanded(
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
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.light_mode, size: 48, color: Colors.orange),
                                    SizedBox(height: 12),
                                    Text(
                                      'وضع فاتح\nLight Mode',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Dark Theme Option
                          Expanded(
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
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.dark_mode, size: 48, color: Color(0xFF1E88E5)),
                                    SizedBox(height: 12),
                                    Text(
                                      'وضع داكن\nDark Mode',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
                    title: 'ما هو هدفك المالي الأساسي؟',
                    content: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _goals.length,
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isSelected = onboarding.selectedGoal == goal['title'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                            fontFamily: 'Amiri',
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
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text(
                        'السابق',
                        style: TextStyle(fontFamily: 'Amiri', fontSize: 16),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 2) {
                        _nextPage();
                      } else {
                        _finish(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'ابدأ الاستخدام 🚀' : 'التالي',
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
            fontFamily: 'Amiri',
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
