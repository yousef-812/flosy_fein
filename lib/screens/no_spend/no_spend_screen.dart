import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/utils/streak_calculator.dart';

class NoSpendScreen extends StatelessWidget {
  const NoSpendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final streaks = calculateNoSpendStreaks(
      provider.transactions,
      now: today,
    );

    final firstRecordedDay = _firstRecordedDay(provider);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startOffset = firstDayOfMonth.weekday % 7;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('no_spend_title')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.green, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StreakValue(
                      label: languageProvider.translate('current_streak'),
                      value: streaks.current,
                      daysLabel: languageProvider.translate('days'),
                      color: Colors.green,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    _StreakValue(
                      label: languageProvider.translate('longest_streak'),
                      value: streaks.longest,
                      daysLabel: languageProvider.translate('days'),
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              languageProvider.translate('calendar_legend'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: daysInMonth + startOffset,
                  itemBuilder: (context, index) {
                    if (index < startOffset) {
                      return const SizedBox.shrink();
                    }

                    final dayNumber = index - startOffset + 1;
                    final date = DateTime(now.year, now.month, dayNumber);
                    final isFuture = date.isAfter(today);
                    final isBeforeTracking = firstRecordedDay == null ||
                        date.isBefore(firstRecordedDay);
                    final hasExpenses = provider.transactions.any(
                      (transaction) =>
                          transaction.isExpense &&
                          transaction.date.day == dayNumber &&
                          transaction.date.month == now.month &&
                          transaction.date.year == now.year,
                    );

                    final cellColor = isFuture || isBeforeTracking
                        ? Colors.grey
                        : hasExpenses
                            ? Colors.red
                            : Colors.green;
                    final opacity = isFuture || isBeforeTracking ? 0.08 : 0.15;

                    return Container(
                      decoration: BoxDecoration(
                        color: cellColor.withOpacity(opacity),
                        border: Border.all(
                          color: cellColor.withOpacity(0.45),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isFuture || isBeforeTracking
                              ? Colors.grey
                              : hasExpenses
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      languageProvider.translate('no_spend_tip_title'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.translate('no_spend_tip_body'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _firstRecordedDay(TransactionProvider provider) {
    if (provider.transactions.isEmpty) return null;

    final dates = provider.transactions
        .map(
          (transaction) => DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          ),
        )
        .toList()
      ..sort();
    return dates.first;
  }
}

class _StreakValue extends StatelessWidget {
  final String label;
  final int value;
  final String daysLabel;
  final Color color;

  const _StreakValue({
    required this.label,
    required this.value,
    required this.daysLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          '$value $daysLabel',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
