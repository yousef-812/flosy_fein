import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';

class TransactionProvider extends ChangeNotifier {
  late Box<TransactionModel> _transactionBox;
  late Box<BudgetModel> _budgetBox;

  List<TransactionModel> _transactions = [];
  List<BudgetModel> _budgets = [];
  String _preferredCurrency = 'ج.م'; // EGP by default (جنيه مصري)

  TransactionProvider() {
    _transactionBox = Hive.box<TransactionModel>('transactionsBox');
    _budgetBox = Hive.box<BudgetModel>('budgetsBox');
    _loadData();
  }

  List<TransactionModel> get transactions => _transactions;
  List<BudgetModel> get budgets => _budgets;
  String get preferredCurrency => _preferredCurrency;

  void _loadData() {
    _transactions = _transactionBox.values.toList();
    _transactions.sort((a, b) => b.date.compareTo(a.date)); // Newest first
    _budgets = _budgetBox.values.toList();
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
    }

    _loadData();
  }

  Future<void> deleteTransaction(String id) async {
    final tx = _transactionBox.get(id);
    if (tx != null) {
      if (tx.isExpense) {
        _updateBudgetSpent(tx.categoryName, -tx.amount); // Refund budget
      }
      await tx.delete();
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
    // Calculate current spent for this category this month
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
}
