import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/challenge_model.dart';

class TransactionProvider extends ChangeNotifier {
  static const String _preferredCurrencyKey = 'preferred_currency';
  static const double _shoppingChallengeLimit = 500;
  static const Set<String> _supportedCurrencies = {
    'ج.م',
    'ر.س',
    'د.إ',
    'د.ك',
    'د.أ',
    'ج.س',
    'دولار',
  };

  late final Box<TransactionModel> _transactionBox;
  late final Box<BudgetModel> _budgetBox;
  late final Box<GoalModel> _goalsBox;
  late final Box<ChallengeModel> _challengesBox;

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<GoalModel> _goals = [];
  List<ChallengeModel> _challenges = [];
  String _preferredCurrency = 'ج.م';

  TransactionModel? _lastDeletedTransaction;

  TransactionProvider() {
    _transactionBox = Hive.box<TransactionModel>('transactionsBox');
    _budgetBox = Hive.box<BudgetModel>('budgetsBox');
    _goalsBox = Hive.box<GoalModel>('goalsBox');
    _challengesBox = Hive.box<ChallengeModel>('challengesBox');

    _loadData();
    _loadPreferredCurrency();
    _initializeDefaultChallenges();
  }

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  List<GoalModel> get goals => List.unmodifiable(_goals);
  List<ChallengeModel> get challenges => List.unmodifiable(_challenges);
  String get preferredCurrency => _preferredCurrency;

  void _loadData() {
    _transactions = _transactionBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final now = DateTime.now();
    _budgets = _budgetBox.values.map((budget) {
      budget.spentAmount = _transactions
          .where(
            (transaction) =>
                transaction.isExpense &&
                transaction.categoryName == budget.categoryName &&
                transaction.date.month == now.month &&
                transaction.date.year == now.year,
          )
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      return budget;
    }).toList();

    _goals = _goalsBox.values.toList();
    _challenges = _challengesBox.values.toList();
    notifyListeners();
  }

  Future<void> _loadPreferredCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString(_preferredCurrencyKey);
    if (savedCurrency == null || !_supportedCurrencies.contains(savedCurrency)) {
      return;
    }

    _preferredCurrency = savedCurrency;
    notifyListeners();
  }

  Future<void> setPreferredCurrency(String currency) async {
    if (!_supportedCurrencies.contains(currency) ||
        currency == _preferredCurrency) {
      return;
    }

    _preferredCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredCurrencyKey, currency);
    notifyListeners();
  }

  double get totalBalance {
    return _transactions.fold<double>(0, (balance, transaction) {
      return transaction.isExpense
          ? balance - transaction.amount
          : balance + transaction.amount;
    });
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where(
          (transaction) =>
              !transaction.isExpense &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  double get monthlyExpenses {
    final now = DateTime.now();
    return _transactions
        .where(
          (transaction) =>
              transaction.isExpense &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    required bool isExpense,
    required String categoryName,
  }) async {
    if (title.trim().isEmpty || categoryName.trim().isEmpty || amount <= 0) {
      return;
    }

    final transaction = TransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: amount,
      date: date,
      isExpense: isExpense,
      categoryName: categoryName.trim(),
    );

    await _transactionBox.put(transaction.id, transaction);
    _loadData();
    await evaluateChallenges();

    // Never send financial values, titles, or categories to Analytics.
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: 'add_transaction',
        parameters: {
          'transaction_type': isExpense ? 'expense' : 'income',
        },
      );
    } catch (error) {
      debugPrint('Firebase Analytics error: $error');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final transaction = _transactionBox.get(id);
    if (transaction == null) return;

    _lastDeletedTransaction = transaction;
    await transaction.delete();
    _loadData();
    await evaluateChallenges();
  }

  Future<void> undoDelete() async {
    final transaction = _lastDeletedTransaction;
    if (transaction == null) return;

    await _transactionBox.put(transaction.id, transaction);
    _lastDeletedTransaction = null;
    _loadData();
    await evaluateChallenges();
  }

  BudgetModel? getBudgetForCategory(String categoryName) {
    try {
      return _budgets.firstWhere(
        (budget) => budget.categoryName == categoryName,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> setBudget(String categoryName, double limit) async {
    if (categoryName.trim().isEmpty || limit <= 0) return;

    final now = DateTime.now();
    final currentSpent = _transactions
        .where(
          (transaction) =>
              transaction.isExpense &&
              transaction.categoryName == categoryName &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year,
        )
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final budget = BudgetModel(
      categoryName: categoryName,
      limitAmount: limit,
      spentAmount: currentSpent,
    );

    await _budgetBox.put(categoryName, budget);
    _loadData();
  }

  Future<void> deleteBudget(String categoryName) async {
    await _budgetBox.delete(categoryName);
    _loadData();
  }

  Future<void> addGoal(String title, double targetAmount) async {
    if (title.trim().isEmpty || targetAmount <= 0) return;

    final goal = GoalModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      targetAmount: targetAmount,
      currentAmount: 0,
      date: DateTime.now(),
    );

    await _goalsBox.put(goal.id, goal);
    _loadData();
  }

  Future<void> updateGoalProgress(String id, double amount) async {
    if (amount <= 0) return;

    final goal = _goalsBox.get(id);
    if (goal == null) return;

    goal.currentAmount =
        (goal.currentAmount + amount).clamp(0.0, goal.targetAmount).toDouble();
    await goal.save();
    _loadData();
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
    _loadData();
  }

  Future<void> _initializeDefaultChallenges() async {
    if (_challengesBox.isEmpty) {
      final now = DateTime.now();
      final defaultChallenges = [
        ChallengeModel(
          id: 'challenge_1',
          title: 'أسبوع بدون شراء قهوة ☕',
          description: 'تجنب شراء أي قهوة أو مشروبات خارجية لمدة 7 أيام للتوفير.',
          targetCategory: 'طعام وشراب',
          targetReductionPercent: 10,
          durationDays: 7,
          startDate: now,
        ),
        ChallengeModel(
          id: 'challenge_2',
          title: 'خفض مصاريف التسوق 🛍️',
          description: 'حاول ألا تتجاوز مصاريف التسوق 500 ج.م هذا الأسبوع.',
          targetCategory: 'تسوق',
          targetReductionPercent: 20,
          durationDays: 7,
          startDate: now,
        ),
        ChallengeModel(
          id: 'challenge_3',
          title: 'يوم بلا مصاريف 🚫',
          description: 'مرر يوماً كاملاً دون تسجيل أي مصروفات على الإطلاق.',
          targetCategory: 'أخرى',
          targetReductionPercent: 100,
          durationDays: 1,
          startDate: now,
        ),
      ];

      for (final challenge in defaultChallenges) {
        await _challengesBox.put(challenge.id, challenge);
      }
      _loadData();
    }

    await evaluateChallenges();
  }

  Future<void> resetChallenges() async {
    await _challengesBox.clear();
    _challenges = [];
    notifyListeners();
    await _initializeDefaultChallenges();
  }

  Future<void> evaluateChallenges() async {
    final now = DateTime.now();
    bool hasChanges = false;

    for (final challenge in _challenges) {
      final start = challenge.startDate;
      final endExclusive = start.add(Duration(days: challenge.durationDays));
      final periodExpenses = _transactions.where((transaction) {
        return transaction.isExpense &&
            !transaction.date.isBefore(start) &&
            transaction.date.isBefore(endExclusive);
      }).toList();

      bool failed;
      switch (challenge.id) {
        case 'challenge_1':
          failed = periodExpenses.any(_isCoffeeExpense);
          break;
        case 'challenge_2':
          final shoppingTotal = periodExpenses
              .where(
                (transaction) =>
                    transaction.categoryName == challenge.targetCategory,
              )
              .fold<double>(0, (sum, transaction) => sum + transaction.amount);
          failed = shoppingTotal > _shoppingChallengeLimit;
          break;
        case 'challenge_3':
          failed = periodExpenses.isNotEmpty;
          break;
        default:
          failed = false;
      }

      final completed = !failed && !now.isBefore(endExclusive);
      if (challenge.isFailed != failed || challenge.isCompleted != completed) {
        challenge.isFailed = failed;
        challenge.isCompleted = completed;
        await challenge.save();
        hasChanges = true;
      }
    }

    if (hasChanges) notifyListeners();
  }

  bool _isCoffeeExpense(TransactionModel transaction) {
    if (transaction.categoryName != 'طعام وشراب') return false;

    final title = transaction.title.toLowerCase();
    const coffeeKeywords = [
      'قهوة',
      'كوفي',
      'كافيه',
      'coffee',
      'cafe',
      'café',
      'latte',
      'لاتيه',
      'cappuccino',
      'كابتشينو',
    ];
    return coffeeKeywords.any(title.contains);
  }
}
