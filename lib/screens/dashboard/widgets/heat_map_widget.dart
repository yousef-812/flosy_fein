import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';

class HeatMapWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const HeatMapWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Generate dates for the last 35 days (to fill a 5x7 grid)
    final List<DateTime> gridDates = [];
    for (int i = 34; i >= 0; i--) {
      gridDates.add(DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.grid_on, size: 18, color: Color(0xFF1E88E5)),
                SizedBox(width: 8),
                Text(
                  'نشاط تسجيل المصاريف (آخر 5 أسابيع)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Amiri'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Grid
            Center(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(gridDates.length, (index) {
                  final date = gridDates[index];
                  // Count transactions on this date
                  final txCount = transactions.where((tx) =>
                      tx.isExpense &&
                      tx.date.day == date.day &&
                      tx.date.month == date.month &&
                      tx.date.year == date.year).length;

                  Color boxColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
                  if (txCount == 1) {
                    boxColor = Colors.green[200]!;
                  } else if (txCount == 2) {
                    boxColor = Colors.green[400]!;
                  } else if (txCount >= 3) {
                    boxColor = Colors.green[700]!;
                  }

                  return Tooltip(
                    message: '${date.day}/${date.month}: سجلت $txCount عمليات',
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: boxColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('أقل ', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Amiri')),
                _buildLegendBox(isDark ? Colors.grey[800]! : Colors.grey[300]!),
                _buildLegendBox(Colors.green[200]!),
                _buildLegendBox(Colors.green[400]!),
                _buildLegendBox(Colors.green[700]!),
                const Text(' أكثر', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Amiri')),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
