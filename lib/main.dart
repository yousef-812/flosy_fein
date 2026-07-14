import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/ad_helper.dart';
import 'models/transaction_model.dart';
import 'models/budget_model.dart';
import 'models/goal_model.dart';
import 'models/challenge_model.dart';
import 'providers/theme_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/gamification_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/transaction/transaction_history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/quick_add_sheet.dart';
import 'core/utils/audio_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and register adapters
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(ChallengeModelAdapter());

  // Open Hive boxes
  await Hive.openBox<TransactionModel>('transactionsBox');
  await Hive.openBox<BudgetModel>('budgetsBox');
  await Hive.openBox<GoalModel>('goalsBox');
  await Hive.openBox<ChallengeModel>('challengesBox');

  // Initialize Google Mobile Ads and set G-Rating programmatically
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      final RequestConfiguration requestConfiguration = RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g, // Family friendly / G-rated ads
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);
    } catch (e) {
      debugPrint('MobileAds initialization failed: $e');
    }
  }

  // Load premium status
  await AdHelper.checkPremiumStatus();

  // Initialize audio helper
  await AudioHelper.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: const FlosyFeinApp(),
    ),
  );
}

class FlosyFeinApp extends StatelessWidget {
  const FlosyFeinApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final onboarding = Provider.of<OnboardingProvider>(context);

    return MaterialApp(
      title: 'فلوسي فين',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CalendarScreen(),
    TransactionHistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'التقويم',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'السجل',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                // Show Quick Add Sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => const QuickAddSheet(),
                );
              },
              backgroundColor: const Color(0xFF1E88E5),
              child: const Icon(Icons.bolt, color: Colors.white),
            )
          : null,
    );
  }
}
