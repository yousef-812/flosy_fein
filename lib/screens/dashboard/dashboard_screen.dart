import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../providers/transaction_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/spending_story_widget.dart';
import '../transaction/add_transaction_screen.dart';
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

  void _triggerCheckInConfetti() {
    setState(() {
      _showCheckInConfetti = true;
    });
    HapticHelper.successTap();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCheckInConfetti = false;
        });
      }
    });
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // App Title & Tagline & Instagram-like Story Circle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Story Circle (Fixed collapsed bug)
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
                            child: Column(
                              children: [
                                Container(
                                  width: 65,
                                  height: 65,
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
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
                                const SizedBox(height: 4),
                                Text(
                                  languageProvider.translate('monthly_story'),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          
                          // Title
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                languageProvider.translate('app_name'),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                              Text(
                                languageProvider.translate('tagline'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          
                          // Coins balance button
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
                                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // "Foloos" Personality Bubble & Daily Insight
                      InsightCard(
                        transactions: provider.transactions,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),

                      // Total Balance Card with Hero & Transition
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
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Text(
                                    languageProvider.translate('remaining_balance_label'),
                                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  AnimatedCounter(
                                    value: balance,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: balance >= 0 ? Colors.green : Colors.red,
                                    ),
                                    suffix: currency,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                languageProvider.translate('income_month_label'),
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '+${income.toStringAsFixed(2)} $currency',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                      Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
                                      Column(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                languageProvider.translate('expenses_label'),
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '-${expenses.toStringAsFixed(2)} $currency',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
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
                      const SizedBox(height: 24),

                      // Recent Transactions Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('recent_transactions'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              HapticHelper.mediumTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                            },
                            child: Text(languageProvider.translate('add_detailed_btn')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Recent Transactions List (At most 3 items)
                      if (provider.transactions.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.asset(
                                    'assets/branding/mascot_waiting.jpg',
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  languageProvider.translate('empty_state_msg'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16, height: 1.5),
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
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: category.color.withOpacity(0.2),
                                child: Icon(category.icon, color: category.color),
                              ),
                              title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tx.isExpense ? Colors.red : Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }),
                      
                      const SizedBox(height: 20),
                      // Banner Ad at the bottom of dashboard
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
