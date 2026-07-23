import '../../models/transaction_model.dart';

class NoSpendStreaks {
  final int current;
  final int longest;

  const NoSpendStreaks({
    required this.current,
    required this.longest,
  });
}

NoSpendStreaks calculateNoSpendStreaks(
  List<TransactionModel> transactions, {
  DateTime? now,
  int lookbackDays = 30,
}) {
  if (transactions.isEmpty || lookbackDays <= 0) {
    return const NoSpendStreaks(current: 0, longest: 0);
  }

  final todaySource = now ?? DateTime.now();
  final today = DateTime(
    todaySource.year,
    todaySource.month,
    todaySource.day,
  );

  final eligibleDates = transactions
      .map((transaction) => DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          ))
      .where((date) => !date.isAfter(today))
      .toList();

  if (eligibleDates.isEmpty) {
    return const NoSpendStreaks(current: 0, longest: 0);
  }

  eligibleDates.sort();
  final firstRecordedDay = eligibleDates.first;
  final lookbackStart = today.subtract(Duration(days: lookbackDays - 1));
  final windowStart = firstRecordedDay.isAfter(lookbackStart)
      ? firstRecordedDay
      : lookbackStart;

  final expenseDays = transactions
      .where((transaction) => transaction.isExpense)
      .map((transaction) => DateTime(
            transaction.date.year,
            transaction.date.month,
            transaction.date.day,
          ))
      .where((date) => !date.isBefore(windowStart) && !date.isAfter(today))
      .toSet();

  int longest = 0;
  int running = 0;
  DateTime cursor = windowStart;
  while (!cursor.isAfter(today)) {
    if (expenseDays.contains(cursor)) {
      running = 0;
    } else {
      running++;
      if (running > longest) longest = running;
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  int current = 0;
  cursor = today;
  while (!cursor.isBefore(windowStart)) {
    if (expenseDays.contains(cursor)) break;
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return NoSpendStreaks(current: current, longest: longest);
}
