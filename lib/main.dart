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
import 'screens/dashboard/analysis_screen.dart';
import 'screens/dashboard/gamification_screen.dart';
import 'screens/transaction/transaction_history_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'widgets/quick_add_sheet.dart';
import 'core/utils/audio_helper.dart';
import 'core/utils/haptic_helper.dart';

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

    final String activeFont = ''; // Use system default font (Roboto/San Francisco/Noto Sans)

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
    AnalysisScreen(),
    GamificationScreen(),
    TransactionHistoryScreen(),
  ];

  int _getNavSelectedIndex(int screenIndex) {
    if (screenIndex <= 1) return screenIndex;
    return screenIndex + 1; // Skip index 2 (Quick Add CTA)
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getNavSelectedIndex(_currentIndex),
        onDestinationSelected: (index) {
          if (index == 2) {
            HapticHelper.mediumTap();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => const QuickAddSheet(),
            );
          } else {
            setState(() {
              _currentIndex = index < 2 ? index : index - 1;
            });
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: languageProvider.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: languageProvider.translate('analysis_nav'),
          ),
          // Symmetrical central Quick Add Button
          NavigationDestination(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_circle, color: Theme.of(context).primaryColor, size: 30),
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_circle, color: Colors.white, size: 30),
            ),
            label: languageProvider.translate('quick_add_title'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.sports_esports_outlined),
            selectedIcon: const Icon(Icons.sports_esports),
            label: languageProvider.translate('gamification_nav'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: languageProvider.translate('history_nav'),
          ),
        ],
      ),
    );
  }
}
