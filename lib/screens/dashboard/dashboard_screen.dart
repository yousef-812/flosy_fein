import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/spending_story_widget.dart';
import '../transaction/add_transaction_screen.dart';
import '../budget/budget_screen.dart';
import '../goals/goals_screen.dart';
import '../challenges/challenges_screen.dart';
import 'widgets/heat_map_widget.dart';
import 'widgets/insight_card.dart';
import 'widgets/animated_counter.dart';
import 'balance_details_screen.dart';
import '../no_spend/no_spend_screen.dart';
import '../wrapped/wrapped_screen.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/language_provider.dart';
import '../shop/streak_shop_screen.dart';
import 'widgets/financial_pet_widget.dart';
import '../../widgets/confetti_widget.dart';
import '../../core/utils/haptic_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showCheckInConfetti = false;

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

        // Group expenses by category for the chart
        final Map<String, double> categoryExpenses = {};
        for (var tx in provider.transactions) {
          if (tx.isExpense) {
            final now = DateTime.now();
            if (tx.date.month == now.month && tx.date.year == now.year) {
              categoryExpenses[tx.categoryName] = 
                  (categoryExpenses[tx.categoryName] ?? 0.0) + tx.amount;
            }
          }
        }

        // Dynamic Color Shading based on balance
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Color dynamicBackgroundColor;
        if (isDark) {
          dynamicBackgroundColor = balance >= 0
              ? Color.lerp(const Color(0xFF121212), Colors.green.shade900.withOpacity(0.15), 0.4)!
              : Color.lerp(const Color(0xFF121212), Colors.red.shade900.withOpacity(0.15), 0.4)!;
        } else {
          dynamicBackgroundColor = balance >= 0
              ? Color.lerp(const Color(0xFFFBF4DF), Colors.green.shade50, 0.4)!
              : Color.lerp(const Color(0xFFFBF4DF), Colors.red.shade50, 0.4)!;
        }

        return Stack(
          children: [
            Scaffold(
              backgroundColor: dynamicBackgroundColor,
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
                      // Story Circle
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
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.purple, Colors.pink, Colors.orange, Colors.yellow],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark ? Colors.black : Colors.white,
                                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 24),
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
                                    child: Image.asset('assets/branding/coin.png', width: 14, height: 14, fit: BoxFit.cover),
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
                  const SizedBox(height: 12),

                  // Financial Pet "Hassala" Mascot
                  const FinancialPetWidget(),
                  const SizedBox(height: 12),

                  // Daily Check-in Gift Card (Only shown if can check in today)
                  Consumer<GamificationProvider>(
                    builder: (context, gamification, child) {
                      if (!gamification.canCheckInToday) return const SizedBox.shrink();
                      return Card(
                        color: Colors.amber.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.amber, width: 2),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset('assets/branding/gift.png', width: 36, height: 36, fit: BoxFit.cover),
                          ),
                          title: Text(
                            languageProvider.translate('daily_checkin_title'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Text(
                            languageProvider.translate('daily_checkin_desc'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              final success = await gamification.claimDailyCheckIn();
                              if (success) {
                                _triggerCheckInConfetti();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(languageProvider.translate('claim_success')),
                                    backgroundColor: Colors.amber,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                            child: Text(
                              languageProvider.translate('claim'),
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    }
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
                              const Text(
                                'الرصيد المتبقي',
                                style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Amiri'),
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
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                                      SizedBox(width: 4),
                                      Text('الدخل (الشهر)', style: TextStyle(color: Colors.grey, fontFamily: 'Amiri')),
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
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                                      SizedBox(width: 4),
                                      Text('المصاريف', style: TextStyle(color: Colors.grey, fontFamily: 'Amiri')),
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
                  const SizedBox(height: 16),

                  // Premium Feature Access Buttons (Horizontal scroll or Grid)
                  Row(
                    children: [
                      _buildQuickFeatureCard(
                        context,
                        title: 'الميزانيات',
                        icon: Icons.pie_chart,
                        color: Colors.purple,
                        screen: const BudgetScreen(),
                      ),
                      const SizedBox(width: 10),
                      _buildQuickFeatureCard(
                        context,
                        title: 'أهدافي',
                        icon: Icons.track_changes,
                        color: Colors.orange,
                        screen: const GoalsScreen(),
                      ),
                      const SizedBox(width: 10),
                      _buildQuickFeatureCard(
                        context,
                        title: 'تحدياتي',
                        icon: Icons.emoji_events,
                        color: Colors.teal,
                        screen: const ChallengesScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickFeatureCard(
                        context,
                        title: 'تقويم الادخار',
                        icon: Icons.calendar_month,
                        color: Colors.green,
                        screen: const NoSpendScreen(),
                      ),
                      const SizedBox(width: 10),
                      _buildQuickFeatureCard(
                        context,
                        title: 'حصاد السنة',
                        icon: Icons.auto_awesome,
                        color: Colors.amber.shade700,
                        screen: WrappedScreen(provider: provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // GitHub-Style Heat Map
                  HeatMapWidget(transactions: provider.transactions),
                  const SizedBox(height: 16),

                  // Analytics / Chart Section
                  if (categoryExpenses.isNotEmpty) ...[
                    const Text(
                      'تحليل مصاريف هذا الشهر',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                              sections: categoryExpenses.entries.map((entry) {
                                final category = CategoryModel.defaultCategories.firstWhere(
                                  (c) => c.name == entry.key,
                                  orElse: () => CategoryModel(name: entry.key, icon: Icons.help, color: Colors.grey),
                                );
                                final percentage = (entry.value / expenses) * 100;
                                return PieChartSectionData(
                                  color: category.color,
                                  value: entry.value,
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: 20,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: categoryExpenses.keys.map((catName) {
                        final category = CategoryModel.defaultCategories.firstWhere(
                          (c) => c.name == catName,
                          orElse: () => CategoryModel(name: catName, icon: Icons.help, color: Colors.grey),
                        );
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: category.color, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(catName, style: const TextStyle(fontSize: 12, fontFamily: 'Amiri')),
                          ],
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    // Empty state funny text (Piggy Bank style)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Image.asset(
                                'assets/branding/mascot_waiting.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لسه مفيش مصاريف متسجلة خالص!\nفلوسك في أمان لحد دلوقتي.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, height: 1.5, fontFamily: 'Amiri'),
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
                              child: const Text('سجل أول عملية الآن', style: TextStyle(fontFamily: 'Amiri')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'آخر المعاملات',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticHelper.mediumTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                          );
                        },
                        child: const Text('إضافة تفصيلية ➕', style: TextStyle(fontFamily: 'Amiri')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Recent Transactions List (At most 3 items)
                  if (provider.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        'لا توجد معاملات بعد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontFamily: 'Amiri'),
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

  Widget _buildQuickFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticHelper.mediumTap();
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, fontFamily: 'Amiri'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
