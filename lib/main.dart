import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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
import 'providers/language_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/transaction/transaction_history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/quick_add_sheet.dart';
import 'core/utils/audio_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and Crashlytics defensively
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

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

  // Initialize language provider
  final languageProvider = LanguageProvider();
  await languageProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
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
    final languageProvider = Provider.of<LanguageProvider>(context);

    final String activeFont = languageProvider.isArabic ? 'Amiri' : '';

    final lightTheme = AppTheme.lightTheme.copyWith(
      textTheme: AppTheme.lightTheme.textTheme.apply(
        fontFamily: activeFont.isEmpty ? null : activeFont,
      ),
    );

    final darkTheme = AppTheme.darkTheme.copyWith(
      textTheme: AppTheme.darkTheme.textTheme.apply(
        fontFamily: activeFont.isEmpty ? null : activeFont,
      ),
    );

    return MaterialApp(
      title: languageProvider.translate('app_name'),
      debugShowCheckedModeBanner: false,
      locale: Locale(languageProvider.currentLanguage),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      theme: lightTheme,
      darkTheme: darkTheme,
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
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: languageProvider.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: languageProvider.translate('calendar_nav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: languageProvider.translate('history_nav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: languageProvider.translate('settings'),
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
