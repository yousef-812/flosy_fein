import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../providers/transaction_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/spending_story_widget.dart';
import '../transaction/add_transaction_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/insight_card.dart';
import 'widgets/animated_counter.dart';
import 'balance_details_screen.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/language_provider.dart';
import '../shop/streak_shop_screen.dart';
import '../../widgets/confetti_widget.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/ad_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCheckInConfetti = false;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    if (kIsWeb || AdHelper.isPremiumUser) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Dashboard InterstitialAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currency = provider.preferredCurrency;
        final balance = provider.totalBalance;
        final income = provider.monthlyIncome;
        final expenses = provider.monthlyExpenses;

        return Stack(
          children: [
            Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. App Bar Header (Settings, Title, Coins)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left Side: Coins Pill
                          Consumer<GamificationProvider>(
                            builder: (context, gamification, child) {
                              return GestureDetector(
                                onTap: () {
                                  HapticHelper.mediumTap();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const StreakShopScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.asset('assets/branding/coin.jpg', width: 14, height: 14, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${gamification.userCoins}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          ),
                          
                          // Center: App Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                languageProvider.translate('app_name'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E88E5),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                languageProvider.translate('tagline'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          // Right Side: Settings Icon Button
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.grey, size: 24),
                            onPressed: () {
                              HapticHelper.mediumTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Symmetrical Actions Row: Story Circle & Streaks
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Story Circle (Fixed size and content)
                          GestureDetector(
                            onTap: () {
                              HapticHelper.mediumTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SpendingStoryWidget(provider: provider),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(1.5),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/branding/mascot_happy.jpg',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  languageProvider.translate('monthly_story'),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          // Vertical Divider
                          Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.2)),

                          // Savings Streak
                          Consumer<GamificationProvider>(
                            builder: (context, gamification, child) {
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageProvider.translate('current_streak'),
                                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                                      ),
                                      Text(
                                        '${gamification.currentStreak} ${languageProvider.translate('days')}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Unified Mascot Tip & Insight Card
                      InsightCard(
                        transactions: provider.transactions,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),

                      // 4. Total Balance Card (Restructured)
                      GestureDetector(
                        onTap: () {
                          HapticHelper.mediumTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BalanceDetailsScreen()),
                          );
                        },
                        child: Hero(
                          tag: 'balance_card_hero',
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    languageProvider.translate('remaining_balance_label'),
                                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedCounter(
                                    value: balance,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: balance >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                    suffix: currency,
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_downward, color: Colors.green, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                languageProvider.translate('income_month_label'),
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+${income.toStringAsFixed(0)} $currency',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      Container(height: 24, width: 1, color: Colors.grey.withOpacity(0.2)),
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_upward, color: Colors.red, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                languageProvider.translate('expenses_label'),
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '-${expenses.toStringAsFixed(0)} $currency',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 5. Recent Transactions Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('recent_transactions'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticHelper.mediumTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                            },
                            child: Text(
                              languageProvider.translate('add_detailed_btn'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // List Items (Restructured Cards)
                      if (provider.transactions.isEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.asset(
                                    'assets/branding/mascot_waiting.jpg',
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  languageProvider.translate('empty_state_msg'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    HapticHelper.mediumTap();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                                    );
                                  },
                                  child: Text(languageProvider.translate('empty_state_btn')),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...provider.transactions.take(3).map((tx) {
                          final category = CategoryModel.defaultCategories.firstWhere(
                            (c) => c.name == tx.categoryName,
                            orElse: () => CategoryModel(name: tx.categoryName, icon: Icons.help, color: Colors.grey),
                          );
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color.withOpacity(0.15),
                                child: Icon(category.icon, color: category.color, size: 20),
                              ),
                              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(
                                '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: Text(
                                '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(0)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tx.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }),
                      
                      const SizedBox(height: 16),
                      // 6. Banner Ad at the bottom
                      const AdBannerWidget(),
                    ],
                  ),
                ),
              ),
            ),
            ConfettiWidget(
              show: _showCheckInConfetti,
              onFinished: () {
                setState(() {
                  _showCheckInConfetti = false;
                });
              },
            ),
          ],
        );
      },
    );
  }
}
