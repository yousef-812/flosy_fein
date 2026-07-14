import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/animated_counter.dart';

class BalanceDetailsScreen extends StatelessWidget {
  const BalanceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currency = provider.preferredCurrency;
    final balance = provider.totalBalance;
    final income = provider.monthlyIncome;
    final expenses = provider.monthlyExpenses;

    // Calculate dynamic background color
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

    // Expiry calculation: if expenses > 0, how many days until balance reaches 0?
    String expiryText = "لا توجد توقعات حالية لعدم وجود مصاريف كافية.";
    final now = DateTime.now();
    final daysPassed = now.day;
    if (expenses > 0 && balance > 0) {
      final dailyRate = expenses / daysPassed;
      final daysLeft = (balance / dailyRate).floor();
      final expiryDate = now.add(Duration(days: daysLeft));
      expiryText = "بمعدل صرفك الحالي (${dailyRate.toStringAsFixed(1)} $currency/يوم)، رصيدك هينفد يوم: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year} (بعد $daysLeft يوم).";
    } else if (balance <= 0) {
      expiryText = "لقد نفد رصيدك بالفعل! الرجاء تقليل المصاريف أو تسجيل دخل جديد لتفادي الديون.";
    }

    return Scaffold(
      backgroundColor: dynamicBackgroundColor,
      appBar: AppBar(
        title: const Text('تفاصيل التدفق المالي', style: TextStyle(fontFamily: 'Amiri')),
        centerTitle: true,
      ),
      body: Hero(
        tag: 'balance_card_hero',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Detailed card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'صافي الرصيد الحالي',
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 8),
                        AnimatedCounter(
                          value: balance,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
                          ),
                          suffix: currency,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Expiry/Prediction Banner Card
                Card(
                  color: balance <= 0 ? Colors.red.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: balance <= 0 ? Colors.red.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.amber, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            expiryText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Income Card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.arrow_downward, color: Colors.green, size: 32),
                    title: const Text('إجمالي المقبوضات (الشهر الحالي)', style: TextStyle(fontFamily: 'Amiri')),
                    trailing: Text(
                      '+${income.toStringAsFixed(2)} $currency',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Expenses Card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.red, size: 32),
                    title: const Text('إجمالي المدفوعات (الشهر الحالي)', style: TextStyle(fontFamily: 'Amiri')),
                    trailing: Text(
                      '-${expenses.toStringAsFixed(2)} $currency',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Tip
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          '💡 نصيحة موازنة الميزانية',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          balance >= 0
                              ? 'أنت في حالة استقرار مالي جيدة حالياً. حاول ادخار 20% من رصيدك الحالي لتحقيق أهدافك بشكل أسرع!'
                              : 'الرصيد بالسالب! يفضل مراجعة ميزانيات الفئات وإيقاف المصاريف غير الضرورية فوراً.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: 'Amiri', fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
