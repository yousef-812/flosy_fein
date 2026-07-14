import 'dart:math';
import '../../models/transaction_model.dart';

class PersonalityHelper {
  // 1. Get Funny Quotes from "Foloos"
  static String getFunnyQuote(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return "مفيش معاملات خالص؟ 🧐 سجلني قبل ما تاكلني بقا!";
    }

    final now = DateTime.now();
    final currentMonthTxs = transactions.where((tx) =>
        tx.date.month == now.month && tx.date.year == now.year).toList();

    if (currentMonthTxs.isEmpty) {
      return "الشهر دا أبيض يا ورد! 🪷 مفيش أي مصروف متسجل لحد دلوقتي.";
    }

    // Check if there was no expense today
    final todayTxs = currentMonthTxs.where((tx) =>
        tx.date.day == now.day &&
        tx.date.month == now.month &&
        tx.date.year == now.year &&
        tx.isExpense).toList();

    if (todayTxs.isEmpty) {
      return "يوم كامل من غير ما تصرف تعريفة! برافو.. إنت كدا في السليم 🦁🏆";
    }

    // Check high single expense
    final hasHugeExpense = currentMonthTxs.any((tx) => tx.isExpense && tx.amount >= 1000);
    if (hasHugeExpense) {
      return "هو إنت ناوي تشتري مصر كلها؟ 😂💸 إيه الأرقام الكبيرة دي!";
    }

    // Calculate categories totals
    double foodSpent = 0;
    double shoppingSpent = 0;
    double totalExpense = 0;

    for (var tx in currentMonthTxs) {
      if (tx.isExpense) {
        totalExpense += tx.amount;
        if (tx.categoryName == 'طعام وشراب') {
          foodSpent += tx.amount;
        } else if (tx.categoryName == 'تسوق') {
          shoppingSpent += tx.amount;
        }
      }
    }

    if (totalExpense > 0) {
      if (foodSpent / totalExpense >= 0.35) {
        return "شكلك بتحب الأكل برة أوي! 🍔 كرشك بيشكرك بس جيبك بيصوت 😂";
      }
      if (shoppingSpent / totalExpense >= 0.30) {
        return "تسوق تاني؟ 🛍️ يا فنان إنت بتشتري السعادة ولا إيه؟ خف شوية 😂";
      }
    }

    // Random default quotes
    final randomQuotes = [
      "برافو... مستمر في التسجيل ومنظم! كمل كدا يا بطل 💪",
      "فلوسك راحت فين؟ 🧐 الميزانية بتقول اهرب بسرعة 😂",
      "سجلني قبل ما تاكلني 😉 عشان نعرف القرش راح فين وجيه منين.",
      "جيبك بيقولك: ارحمني يا فاعل الخير 💸😂",
    ];

    return randomQuotes[Random().nextInt(randomQuotes.length)];
  }

  // 2. Get Daily Insights List
  static List<String> getDailyInsights(List<TransactionModel> transactions, String currency) {
    final List<String> insights = [];
    final now = DateTime.now();

    if (transactions.isEmpty) {
      insights.add("ابدأ بتسجيل مصاريفك اليوم لتحصل على تحليلات دقيقة هنا 📊");
      insights.add("توفير 50 جنيه يوميًا يعني 18,250 جنيه ادخار في السنة! 💰");
      return insights;
    }

    // Insight 1: Today vs Yesterday
    double todaySpent = 0;
    double yesterdaySpent = 0;
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var tx in transactions) {
      if (tx.isExpense) {
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (txDate == today) {
          todaySpent += tx.amount;
        } else if (txDate == yesterday) {
          yesterdaySpent += tx.amount;
        }
      }
    }

    if (todaySpent > 0 && yesterdaySpent > 0) {
      if (todaySpent < yesterdaySpent) {
        final diffPercent = ((yesterdaySpent - todaySpent) / yesterdaySpent) * 100;
        insights.add("📊 مصاريفك النهاردة أقل من أمس بـ ${diffPercent.toStringAsFixed(0)}%.. عاش يا بطل! 👏");
      } else if (todaySpent > yesterdaySpent) {
        final diffPercent = ((todaySpent - yesterdaySpent) / yesterdaySpent) * 100;
        insights.add("⚠️ مصاريفك النهاردة أعلى من أمس بـ ${diffPercent.toStringAsFixed(0)}%.. محتاجين نربط الحزام شويتين.");
      }
    } else if (todaySpent == 0 && yesterdaySpent > 0) {
      insights.add("📊 ممتاز! لم تصرف أي شيء اليوم مقارنة بـ ${yesterdaySpent.toStringAsFixed(2)} $currency أمس.");
    }

    // Insight 2: Top category this month
    final Map<String, double> categoryMap = {};
    double totalMonthExpenses = 0;
    for (var tx in transactions) {
      if (tx.isExpense && tx.date.month == now.month && tx.date.year == now.year) {
        categoryMap[tx.categoryName] = (categoryMap[tx.categoryName] ?? 0) + tx.amount;
        totalMonthExpenses += tx.amount;
      }
    }

    if (categoryMap.isNotEmpty) {
      String topCategory = '';
      double maxAmount = 0;
      categoryMap.forEach((key, value) {
        if (value > maxAmount) {
          maxAmount = value;
          topCategory = key;
        }
      });

      if (topCategory.isNotEmpty && totalMonthExpenses > 0) {
        final percent = (maxAmount / totalMonthExpenses) * 100;
        insights.add("☕ أكتر فئة صرفت عليها الشهر ده هي '$topCategory' بنسبة ${percent.toStringAsFixed(0)}% من إجمالي مصاريفك.");
      }
    }

    // Insight 3: Month-end projection
    final daysPassed = now.day;
    if (daysPassed >= 5 && totalMonthExpenses > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projectedExpenses = (totalMonthExpenses / daysPassed) * daysInMonth;
      insights.add("🔮 متوقع تصرف حوالي ${projectedExpenses.toStringAsFixed(0)} $currency بنهاية الشهر الحالي لو مشيت بنفس المعدل.");
    }

    // Insight 4: Savings rule projection
    final randomSavingsAmount = [10, 20, 50, 100];
    final selectedSaving = randomSavingsAmount[Random().nextInt(randomSavingsAmount.length)];
    final yearlySaving = selectedSaving * 365;
    insights.add("💡 نصيحة: لو وفرت $selectedSaving $currency يومياً، هتحوش $yearlySaving $currency في السنة! 💰");

    return insights;
  }
}
