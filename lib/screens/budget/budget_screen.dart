import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../../core/utils/ad_helper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _limitController = TextEditingController();
  String _selectedCategory = CategoryModel.defaultCategories.first.name;

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (kIsWeb || AdHelper.isPremiumUser) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final limitText = _limitController.text.trim();
    if (limitText.isEmpty) return;

    final limit = double.tryParse(limitText);
    if (limit == null || limit <= 0) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    void performSave() {
      Provider.of<TransactionProvider>(context, listen: false)
          .setBudget(_selectedCategory, limit);
      _limitController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            languageProvider
                .translate('budget_added_success')
                .replaceFirst('{}', languageProvider.translateCategory(_selectedCategory)),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }

    if (_isAdLoaded && _interstitialAd != null && AdHelper.canShowInterstitial) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          AdHelper.recordInterstitialShown();
          performSave();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          performSave();
        },
      );
      _interstitialAd!.show();
    } else {
      performSave();
    }
  }

  void _showAddBudgetDialog() {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16.0,
                16.0,
                16.0,
                MediaQuery.of(context).viewInsets.bottom + 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    lp.translate('set_budget_category'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: lp.translate('select_category_label'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: CategoryModel.defaultCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.name,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color),
                            const SizedBox(width: 10),
                            Text(lp.translateCategory(cat.name)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Budget Limit Input
                  TextField(
                    controller: _limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: lp.translate('budget_limit_hint'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.currency_exchange),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveBudget,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(lp.translate('save_budget'), style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('monthly_budgets')),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final currency = provider.preferredCurrency;

          if (provider.budgets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      languageProvider.translate('no_budgets_msg'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddBudgetDialog,
                      icon: const Icon(Icons.add),
                      label: Text(languageProvider.translate('set_budget_now')),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: provider.budgets.length,
            itemBuilder: (context, index) {
              final budget = provider.budgets[index];
              final category = CategoryModel.defaultCategories.firstWhere(
                (c) => c.name == budget.categoryName,
                orElse: () => CategoryModel(name: budget.categoryName, icon: Icons.help, color: Colors.grey),
              );

              final percent = budget.limitAmount > 0 
                  ? (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0)
                  : 0.0;
              final isOverrun = budget.spentAmount >= budget.limitAmount;
              final isWarning = budget.spentAmount >= budget.limitAmount * 0.8;

              Color progressColor = Colors.green;
              if (isOverrun) {
                progressColor = Colors.red;
              } else if (isWarning) {
                progressColor = Colors.orange;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(category.icon, color: category.color),
                              const SizedBox(width: 8),
                              Text(
                                languageProvider.translateCategory(budget.categoryName),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              provider.deleteBudget(budget.categoryName);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          color: progressColor,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Amounts info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('consumed_amount')
                                .replaceFirst('{}', budget.spentAmount.toStringAsFixed(2))
                                .replaceFirst('{}', currency),
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: isOverrun ? Colors.red : null,
                            ),
                          ),
                          Text(
                            languageProvider.translate('limit_amount')
                                .replaceFirst('{}', budget.limitAmount.toStringAsFixed(2))
                                .replaceFirst('{}', currency),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      if (isOverrun) ...[
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.translate('budget_exceeded_warning'),
                          style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ] else if (isWarning) ...[
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.translate('budget_warning_80'),
                          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.budgets.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: _showAddBudgetDialog,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
