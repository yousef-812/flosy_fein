import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/utils/haptic_helper.dart';

class NoSpendScreen extends StatelessWidget {
  const NoSpendScreen({super.key});

  // Calculate streaks
  Map<String, int> _calculateStreaks(List<TransactionModel> transactions) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final now = DateTime.now();
    // Check the last 30 days
    for (int i = 29; i >= 0; i--) {
      final checkDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final hasExpense = transactions.any((tx) =>
          tx.isExpense &&
          tx.date.day == checkDate.day &&
          tx.date.month == checkDate.month &&
          tx.date.year == checkDate.year);

      if (!hasExpense) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // Current streak (counting backwards from today)
    for (int i = 0; i < 30; i++) {
      final checkDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final hasExpense = transactions.any((tx) =>
          tx.isExpense &&
          tx.date.day == checkDate.day &&
          tx.date.month == checkDate.month &&
          tx.date.year == checkDate.year);

      if (!hasExpense) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {
      'current': currentStreak,
      'longest': longestStreak,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final streaks = _calculateStreaks(provider.transactions);
    final now = DateTime.now();

    // Days of the current month grid
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday;
    final startOffset = (startWeekday % 7);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقويم أيام الادخار', style: TextStyle(fontFamily: 'Amiri')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Streak Header Card
            Card(
              color: Colors.green.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.green, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('السلسلة الحالية', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '${streaks['current']} أيام',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
                    Column(
                      children: [
                        const Text('أطول سلسلة ادخار', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '${streaks['longest']} أيام',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // No Spend Calendar Legend
            const Text(
              'أيام الشهر الحالي (الأخضر = بلا صرف | الأحمر = صرف)',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Calendar Grid View (Mockup of current month)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: daysInMonth + startOffset,
                  itemBuilder: (context, index) {
                    if (index < startOffset) {
                      return const SizedBox.shrink();
                    }

                    final dayNumber = index - startOffset + 1;
                    final date = DateTime(now.year, now.month, dayNumber);
                    
                    // Check if date has expenses
                    final hasExpenses = provider.transactions.any((tx) =>
                        tx.isExpense &&
                        tx.date.day == dayNumber &&
                        tx.date.month == now.month &&
                        tx.date.year == now.year);

                    Color cellColor = Colors.green;
                    if (hasExpenses) {
                      cellColor = Colors.red;
                    }

                    // Disable future days
                    final isFuture = date.isAfter(now);
                    if (isFuture) {
                      cellColor = Colors.grey.withOpacity(0.3);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: cellColor.withOpacity(0.15),
                        border: Border.all(color: cellColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isFuture ? Colors.grey : (cellColor == Colors.green ? Colors.green.shade700 : Colors.red.shade700),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Motivational quote
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('💡 نصيحة فلوس لليوم:', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 8),
                    Text(
                      'المنافسة الحقيقية هي كسر رقمك القياسي في الادخار! حافظ على المربعات الخضراء 🟢 لأطول فترة ممكنة لتبني عادات مالية لا تقهر 😉.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: Colors.grey),
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
}
