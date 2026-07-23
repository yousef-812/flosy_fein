import 'package:flutter_test/flutter_test.dart';
import 'package:flosy_fein/core/utils/streak_calculator.dart';
import 'package:flosy_fein/models/transaction_model.dart';

TransactionModel transaction({
  required String id,
  required DateTime date,
  required bool isExpense,
}) {
  return TransactionModel(
    id: id,
    title: isExpense ? 'Expense' : 'Income',
    amount: 10,
    date: date,
    isExpense: isExpense,
    categoryName: 'أخرى',
  );
}

void main() {
  group('calculateNoSpendStreaks', () {
    final today = DateTime(2026, 7, 23);

    test('returns zero for a new user', () {
      final result = calculateNoSpendStreaks([], now: today);

      expect(result.current, 0);
      expect(result.longest, 0);
    });

    test('does not count days before the first recorded transaction', () {
      final result = calculateNoSpendStreaks(
        [
          transaction(
            id: '1',
            date: DateTime(2026, 7, 21),
            isExpense: true,
          ),
        ],
        now: today,
      );

      expect(result.current, 2);
      expect(result.longest, 2);
    });

    test('income-only day can begin a no-spend streak', () {
      final result = calculateNoSpendStreaks(
        [
          transaction(
            id: '1',
            date: today,
            isExpense: false,
          ),
        ],
        now: today,
      );

      expect(result.current, 1);
      expect(result.longest, 1);
    });

    test('an expense today resets the current streak', () {
      final result = calculateNoSpendStreaks(
        [
          transaction(
            id: '1',
            date: DateTime(2026, 7, 21),
            isExpense: false,
          ),
          transaction(
            id: '2',
            date: today,
            isExpense: true,
          ),
        ],
        now: today,
      );

      expect(result.current, 0);
      expect(result.longest, 2);
    });
  });
}
