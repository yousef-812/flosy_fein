import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import '../transaction/add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App title & funny tagline
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'فلوسي فين',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      Text(
                        '« سجلني قبل ما تاكلني »',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Amiri',
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Total Balance Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'الرصيد المتبقي',
                            style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Amiri'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${balance.toStringAsFixed(2)} $currency',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red,
                            ),
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
                  const SizedBox(height: 20),

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
                    // Empty state funny text
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.monetization_on_outlined, size: 64, color: Colors.orange.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'مفيش مصاريف متسجلة هذا الشهر! 🥳\nفلوسك في أمان لحد دلوقتي، سجلني قبل ما تاكلني!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, height: 1.5, fontFamily: 'Amiri'),
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
                      if (provider.transactions.length > 3)
                        TextButton(
                          onPressed: () {
                            // Can be linked to Tab change in main screen
                          },
                          child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Amiri')),
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
        );
      },
    );
  }
}
