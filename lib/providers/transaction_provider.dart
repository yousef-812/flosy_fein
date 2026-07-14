import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/challenge_model.dart';

class TransactionProvider extends ChangeNotifier {
  late Box<TransactionModel> _transactionBox;
  late Box<BudgetModel> _budgetBox;
  late Box<GoalModel> _goalsBox;
  late Box<ChallengeModel> _challengesBox;

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  List<GoalModel> _goals = [];
  List<ChallengeModel> _challenges = [];
  String _preferredCurrency = 'ج.م'; // Default

  // Temporary storage for Undo Action
  TransactionModel? _lastDeletedTransaction;
  int? _lastDeletedIndex;

  TransactionProvider() {
    _transactionBox = Hive.box<TransactionModel>('transactionsBox');
    _budgetBox = Hive.box<BudgetModel>('budgetsBox');
    _goalsBox = Hive.box<GoalModel>('goalsBox');
    _challengesBox = Hive.box<ChallengeModel>('challengesBox');
    _loadData();
    _initializeDefaultChallenges();
  }

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  List<GoalModel> get goals => _goals;
  List<ChallengeModel> get challenges => _challenges;
  String get preferredCurrency => _preferredCurrency;

  void _loadData() {
    _transactions = _transactionBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    _budgets = _budgetBox.values.toList();
    _goals = _goalsBox.values.toList();
    _challenges = _challengesBox.values.toList();
    notifyListeners();
  }

  Future<void> setPreferredCurrency(String currency) async {
    _preferredCurrency = currency;
    notifyListeners();
  }

  // Financial calculations
  double get totalBalance {
    double balance = 0;
    for (var tx in _transactions) {
      if (tx.isExpense) {
        balance -= tx.amount;
      } else {
        balance += tx.amount;
      }
    }
    return balance;
  }

  double get monthlyIncome {
    double income = 0;
    final now = DateTime.now();
    for (var tx in _transactions) {
      if (!tx.isExpense && tx.date.month == now.month && tx.date.year == now.year) {
        income += tx.amount;
      }
    }
    return income;
  }

  double get monthlyExpenses {
    double expenses = 0;
    final now = DateTime.now();
    for (var tx in _transactions) {
      if (tx.isExpense && tx.date.month == now.month && tx.date.year == now.year) {
        expenses += tx.amount;
      }
    }
    return expenses;
  }

  // CRUD for transactions
  Future<void> addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    required bool isExpense,
    required String categoryName,
  }) async {
    final tx = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      date: date,
      isExpense: isExpense,
      categoryName: categoryName,
    );
    await _transactionBox.put(tx.id, tx);
    
    // Update budget consumption if it's an expense
    if (isExpense) {
      _updateBudgetSpent(categoryName, amount);
      _checkChallengesOnExpenseAdded(categoryName, amount);
    }

    _loadData();
  }

  Future<void> deleteTransaction(String id) async {
    final tx = _transactionBox.get(id);
    if (tx != null) {
      // Store for Undo
      _lastDeletedTransaction = tx;
      _lastDeletedIndex = _transactions.indexOf(tx);

      if (tx.isExpense) {
        _updateBudgetSpent(tx.categoryName, -tx.amount); // Refund budget
        _checkChallengesOnExpenseDeleted(tx.categoryName, tx.amount);
      }
      await tx.delete();
      _loadData();
    }
  }

  // Undo Delete Method
  Future<void> undoDelete() async {
    if (_lastDeletedTransaction != null) {
      final tx = _lastDeletedTransaction!;
      await _transactionBox.put(tx.id, tx);
      if (tx.isExpense) {
        _updateBudgetSpent(tx.categoryName, tx.amount);
        _checkChallengesOnExpenseAdded(tx.categoryName, tx.amount);
      }
      _lastDeletedTransaction = null;
      _lastDeletedIndex = null;
      _loadData();
    }
  }

  // Budget calculations and management
  BudgetModel? getBudgetForCategory(String categoryName) {
    try {
      return _budgets.firstWhere((b) => b.categoryName == categoryName);
    } catch (_) {
      return null;
    }
  }

  Future<void> setBudget(String categoryName, double limit) async {
    double currentSpent = 0;
    final now = DateTime.now();
    for (var tx in _transactions) {
      if (tx.isExpense && tx.categoryName == categoryName && tx.date.month == now.month && tx.date.year == now.year) {
        currentSpent += tx.amount;
      }
    }

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

  void _updateBudgetSpent(String categoryName, double amount) {
    final budget = _budgetBox.get(categoryName);
    if (budget != null) {
      budget.spentAmount += amount;
      if (budget.spentAmount < 0) budget.spentAmount = 0;
      budget.save();
    }
  }

  // GOALS Management
  Future<void> addGoal(String title, double targetAmount) async {
    final goal = GoalModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      date: DateTime.now(),
    );
    await _goalsBox.put(goal.id, goal);
    _loadData();
  }

  Future<void> updateGoalProgress(String id, double amount) async {
    final goal = _goalsBox.get(id);
    if (goal != null) {
      goal.currentAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
      await goal.save();
      _loadData();
    }
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
    _loadData();
  }

  // CHALLENGES Management
  void _initializeDefaultChallenges() {
    if (_challengesBox.isEmpty) {
      final defaultList = [
        ChallengeModel(
          id: 'challenge_1',
          title: 'أسبوع بدون شراء قهوة ☕',
          description: 'تجنب شراء أي قهوة أو مشروبات خارجية لمدة 7 أيام للتوفير.',
          targetCategory: 'طعام وشراب',
          targetReductionPercent: 10,
          durationDays: 7,
          startDate: DateTime.now(),
        ),
        ChallengeModel(
          id: 'challenge_2',
          title: 'خفض مصاريف التسوق 🛍️',
          description: 'حاول ألا تتجاوز مصاريف التسوق 500 ج.م هذا الأسبوع.',
          targetCategory: 'تسوق',
          targetReductionPercent: 20,
          durationDays: 7,
          startDate: DateTime.now(),
        ),
        ChallengeModel(
          id: 'challenge_3',
          title: 'يوم بلا مصاريف 🚫',
          description: 'مرر يوماً كاملاً دون تسجيل أي مصروفات على الإطلاق.',
          targetCategory: 'أخرى',
          targetReductionPercent: 100,
          durationDays: 1,
          startDate: DateTime.now(),
        ),
      ];
      for (var ch in defaultList) {
        _challengesBox.put(ch.id, ch);
      }
      _loadData();
    }
  }

  Future<void> resetChallenges() async {
    await _challengesBox.clear();
    _initializeDefaultChallenges();
  }

  void _checkChallengesOnExpenseAdded(String category, double amount) {
    for (var ch in _challenges) {
      if (!ch.isCompleted && !ch.isFailed) {
        if (ch.targetCategory == category) {
          if (ch.id == 'challenge_1' && (ch.title.contains('قهوة') || ch.title.contains('شراء'))) {
            // Coffee challenge: fail if user spends on food/drink with title 'قهوة'
            // We can check if title contains coffee, done at screen level or transaction level
          }
        }
      }
    }
  }

  void _checkChallengesOnExpenseDeleted(String category, double amount) {
    // Implement logic if deleting an expense updates challenge progress
  }
}
