import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/spending_story_widget.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/streak_calculator.dart';
import '../transaction/add_transaction_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/streak_shop_screen.dart';
import 'widgets/insight_card.dart';
import 'widgets/animated_counter.dart';
import 'balance_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currency = provider.preferredCurrency;
        final balance = provider.totalBalance;
        final income = provider.monthlyIncome;
        final expenses = provider.monthlyExpenses;
        final streaks = calculateNoSpendStreaks(provider.transactions);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(languageProvider: languageProvider),
                  const SizedBox(height: 16),
                  _DashboardActions(
                    provider: provider,
                    streak: streaks.current,
                    languageProvider: languageProvider,
                  ),
                  const SizedBox(height: 16),
                  InsightCard(
                    transactions: provider.transactions,
                    currency: currency,
                  ),
                  const SizedBox(height: 16),
                  _BalanceCard(
                    balance: balance,
                    income: income,
                    expenses: expenses,
                    currency: currency,
                    languageProvider: languageProvider,
                  ),
                  const SizedBox(height: 20),
                  _RecentTransactions(
                    provider: provider,
                    currency: currency,
                    languageProvider: languageProvider,
                  ),
                  const SizedBox(height: 16),
                  const AdBannerWidget(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final LanguageProvider languageProvider;

  const _DashboardHeader({required this.languageProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Consumer<GamificationProvider>(
          builder: (context, gamification, child) {
            return GestureDetector(
              onTap: () {
                HapticHelper.mediumTap();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StreakShopScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        'assets/branding/coin.jpg',
                        width: 14,
                        height: 14,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${gamification.userCoins}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
        IconButton(
          icon: const Icon(
            Icons.settings_outlined,
            color: Colors.grey,
            size: 24,
          ),
          onPressed: () {
            HapticHelper.mediumTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }
}

class _DashboardActions extends StatelessWidget {
  final TransactionProvider provider;
  final int streak;
  final LanguageProvider languageProvider;

  const _DashboardActions({
    required this.provider,
    required this.streak,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
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
                    colors: [
                      Colors.purple,
                      Colors.pink,
                      Colors.orange,
                      Colors.yellow,
                    ],
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
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 24,
          width: 1,
          color: Colors.grey.withOpacity(0.2),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('current_streak'),
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$streak ${languageProvider.translate('days')}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final String currency;
  final LanguageProvider languageProvider;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.currency,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  languageProvider.translate('remaining_balance_label'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedCounter(
                  value: balance,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: balance >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  suffix: currency,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MoneySummary(
                      icon: Icons.arrow_downward,
                      label: languageProvider.translate('income_month_label'),
                      amount: '+${income.toStringAsFixed(0)} $currency',
                      color: Colors.green,
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    _MoneySummary(
                      icon: Icons.arrow_upward,
                      label: languageProvider.translate('expenses_label'),
                      amount: '-${expenses.toStringAsFixed(0)} $currency',
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneySummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _MoneySummary({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final TransactionProvider provider;
  final String currency;
  final LanguageProvider languageProvider;

  const _RecentTransactions({
    required this.provider,
    required this.currency,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageProvider.translate('recent_transactions'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                HapticHelper.mediumTap();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
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
        if (provider.transactions.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      HapticHelper.mediumTap();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddTransactionScreen(),
                        ),
                      );
                    },
                    child: Text(
                      languageProvider.translate('empty_state_btn'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...provider.transactions.take(3).map((transaction) {
            final category = CategoryModel.defaultCategories.firstWhere(
              (item) => item.name == transaction.categoryName,
              orElse: () => CategoryModel(
                name: transaction.categoryName,
                icon: Icons.help,
                color: Colors.grey,
              ),
            );

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withOpacity(0.12)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color.withOpacity(0.15),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                title: Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                trailing: Text(
                  '${transaction.isExpense ? '-' : '+'}${transaction.amount.toStringAsFixed(0)} $currency',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: transaction.isExpense
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
