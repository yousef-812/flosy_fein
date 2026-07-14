import 'dart:math';
import '../../models/transaction_model.dart';

class PersonalityHelper {
  // 1. Get Funny Quotes from "Foloos"
  static String getFunnyQuote(List<TransactionModel> transactions, [String langCode = 'ar']) {
    final isAr = langCode == 'ar';

    if (transactions.isEmpty) {
      return isAr 
          ? "مفيش معاملات خالص؟ 🧐 سجلني قبل ما تاكلني بقا!"
          : "No transactions yet? 🧐 C'mon, track me before you eat me!";
    }

    final now = DateTime.now();
    final currentMonthTxs = transactions.where((tx) =>
        tx.date.month == now.month && tx.date.year == now.year).toList();

    if (currentMonthTxs.isEmpty) {
      return isAr
          ? "الشهر دا أبيض يا ورد! 🪷 مفيش أي مصروف متسجل لحد دلوقتي."
          : "A clean sheet this month! 🪷 No expenses recorded so far.";
    }

    // Check if there was no expense today
    final todayTxs = currentMonthTxs.where((tx) =>
        tx.date.day == now.day &&
        tx.date.month == now.month &&
        tx.date.year == now.year &&
        tx.isExpense).toList();

    if (todayTxs.isEmpty) {
      return isAr
          ? "يوم كامل من غير ما تصرف تعريفة! برافو.. إنت كدا في السليم 🦁🏆"
          : "A whole day with zero spending! Bravo.. you're on the safe side 🦁🏆";
    }

    // Check high single expense
    final hasHugeExpense = currentMonthTxs.any((tx) => tx.isExpense && tx.amount >= 1000);
    if (hasHugeExpense) {
      return isAr
          ? "هو إنت ناوي تشتري مصر كلها؟ 😂💸 إيه الأرقام الكبيرة دي!"
          : "Are you trying to buy the whole country? 😂💸 What are these huge numbers!";
    }

    // Calculate categories totals
    double foodSpent = 0;
    double shoppingSpent = 0;
    double totalExpense = 0;

    for (var tx in currentMonthTxs) {
      if (tx.isExpense) {
        totalExpense += tx.amount;
        if (tx.categoryName == 'طعام وشراب' || tx.categoryName == 'Food & Drinks') {
          foodSpent += tx.amount;
        } else if (tx.categoryName == 'تسوق' || tx.categoryName == 'Shopping') {
          shoppingSpent += tx.amount;
        }
      }
    }

    if (totalExpense > 0) {
      if (foodSpent / totalExpense >= 0.35) {
        return isAr
            ? "شكلك بتحب الأكل برة أوي! 🍔 كرشك بيشكرك بس جيبك بيصوت 😂"
            : "Seems like you love eating out! 🍔 Your stomach is thanking you but your wallet is crying 😂";
      }
      if (shoppingSpent / totalExpense >= 0.30) {
        return isAr
            ? "تسوق تاني؟ 🛍️ يا فنان إنت بتشتري السعادة ولا إيه؟ خف شوية 😂"
            : "Shopping again? 🛍️ Are you buying happiness or what? Go easy! 😂";
      }
    }

    // Random default quotes
    final randomQuotesAr = [
      "برافو... مستمر في التسجيل ومنظم! كمل كدا يا بطل 💪",
      "فلوسك راحت فين؟ 🧐 الميزانية بتقول اهرب بسرعة 😂",
      "سجلني قبل ما تاكلني 😉 عشان نعرف القرش راح فين وجيه منين.",
      "جيبك بيقولك: ارحمني يا فاعل الخير 💸😂",
    ];

    final randomQuotesEn = [
      "Bravo... you are consistent and organized! Keep it up champion 💪",
      "Where did your money go? 🧐 The budget says: run for your life! 😂",
      "Track me before you eat me 😉 so we know where every penny went.",
      "Your wallet says: have mercy, kind stranger 💸😂",
    ];

    final list = isAr ? randomQuotesAr : randomQuotesEn;
    return list[Random().nextInt(list.length)];
  }

  // 2. Get Daily Insights List
  static List<String> getDailyInsights(List<TransactionModel> transactions, String currency, [String langCode = 'ar']) {
    final List<String> insights = [];
    final now = DateTime.now();
    final isAr = langCode == 'ar';

    if (transactions.isEmpty) {
      if (isAr) {
        insights.add("ابدأ بتسجيل مصاريفك اليوم لتحصل على تحليلات دقيقة هنا 📊");
        insights.add("توفير 50 جنيه يوميًا يعني 18,250 جنيه ادخار في السنة! 💰");
      } else {
        insights.add("Start recording your expenses today to get accurate insights here 📊");
        insights.add("Saving 50 units daily means 18,250 saved in a year! 💰");
      }
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
        insights.add(isAr
            ? "📊 مصاريفك النهاردة أقل من أمس بـ ${diffPercent.toStringAsFixed(0)}%.. عاش يا بطل! 👏"
            : "📊 Today's expenses are lower than yesterday by ${diffPercent.toStringAsFixed(0)}%.. Awesome job! 👏");
      } else if (todaySpent > yesterdaySpent) {
        final diffPercent = ((todaySpent - yesterdaySpent) / yesterdaySpent) * 100;
        insights.add(isAr
            ? "⚠️ مصاريفك النهاردة أعلى من أمس بـ ${diffPercent.toStringAsFixed(0)}%.. محتاجين نربط الحزام شويتين."
            : "⚠️ Today's expenses are higher than yesterday by ${diffPercent.toStringAsFixed(0)}%.. Time to tighten the belt a bit.");
      }
    } else if (todaySpent == 0 && yesterdaySpent > 0) {
      insights.add(isAr
          ? "📊 ممتاز! لم تصرف أي شيء اليوم مقارنة بـ ${yesterdaySpent.toStringAsFixed(2)} $currency أمس."
          : "📊 Excellent! You spent nothing today compared to ${yesterdaySpent.toStringAsFixed(2)} $currency yesterday.");
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
        insights.add(isAr
            ? "☕ أكتر فئة صرفت عليها الشهر ده هي '$topCategory' بنسبة ${percent.toStringAsFixed(0)}% من إجمالي مصاريفك."
            : "☕ Your highest spending category this month is '$topCategory' making up ${percent.toStringAsFixed(0)}% of total expenses.");
      }
    }

    // Insight 3: Month-end projection
    final daysPassed = now.day;
    if (daysPassed >= 5 && totalMonthExpenses > 0) {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final projectedExpenses = (totalMonthExpenses / daysPassed) * daysInMonth;
      insights.add(isAr
          ? "🔮 متوقع تصرف حوالي ${projectedExpenses.toStringAsFixed(0)} $currency بنهاية الشهر الحالي لو مشيت بنفس المعدل."
          : "🔮 Projected to spend around ${projectedExpenses.toStringAsFixed(0)} $currency by the end of this month if you continue at this rate.");
    }

    // Insight 4: Savings rule projection
    final randomSavingsAmount = [10, 20, 50, 100];
    final selectedSaving = randomSavingsAmount[Random().nextInt(randomSavingsAmount.length)];
    final yearlySaving = selectedSaving * 365;
    insights.add(isAr
        ? "💡 نصيحة: لو وفرت $selectedSaving $currency يومياً، هتحوش $yearlySaving $currency في السنة! 💰"
        : "💡 Tip: If you save $selectedSaving $currency daily, you will save $yearlySaving $currency in a year! 💰");

    return insights;
  }
}
