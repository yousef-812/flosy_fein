import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_banner_widget.dart';
import 'widgets/heat_map_widget.dart';
import '../budget/budget_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('analytics_title')),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final currency = provider.preferredCurrency;
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

          final hasData = categoryExpenses.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Monthly Expense Breakdown Card (Pie Chart)
                Text(
                  languageProvider.translate('monthly_analysis'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: hasData
                        ? Column(
                            children: [
                              SizedBox(
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
                                        radius: 22,
                                        showTitle: false,
                                        badgeWidget: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: category.color, width: 1.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.12),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: category.color,
                                            ),
                                          ),
                                        ),
                                        badgePositionPercentageOffset: 0.9,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        languageProvider.translateCategory(catName),
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                        : Container(
                            height: 180,
                            alignment: Alignment.center,
                            child: Text(
                              languageProvider.translate('no_transactions_yet'),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Spending Activity Heat Map
                Text(
                  languageProvider.translate('activity_map'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                HeatMapWidget(transactions: provider.transactions),
                const SizedBox(height: 20),

                // 3. Budgets Progress Bars
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('budgets'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 14),
                      label: Text(
                        languageProvider.translate('budgets'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (provider.budgets.isEmpty)
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
                          Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            languageProvider.translate('no_budgets_msg'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BudgetScreen()),
                              );
                            },
                            child: Text(languageProvider.translate('set_budget_now')),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...provider.budgets.map((budget) {
                    final category = CategoryModel.defaultCategories.firstWhere(
                      (c) => c.name == budget.categoryName,
                      orElse: () => CategoryModel(name: budget.categoryName, icon: Icons.help, color: Colors.grey),
                    );

                    final percent = budget.limitAmount > 0 
                        ? (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0)
                        : 0.0;
                    final isOverrun = budget.spentAmount >= budget.limitAmount;
                    final isWarning = budget.spentAmount >= budget.limitAmount * 0.8;

                    Color progressColor = Colors.green;
                    if (isOverrun) {
                      progressColor = Colors.red;
                    } else if (isWarning) {
                      progressColor = Colors.orange;
                    }

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(category.icon, color: category.color, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  languageProvider.translateCategory(budget.categoryName),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                Text(
                                  '${budget.spentAmount.toStringAsFixed(0)} / ${budget.limitAmount.toStringAsFixed(0)} $currency',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: percent,
                                color: progressColor,
                                backgroundColor: Colors.grey.withOpacity(0.15),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),
                // 4. Banner Ad in Analysis tab
                const AdBannerWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
