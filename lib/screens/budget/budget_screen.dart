import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/transaction_provider.dart';
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

    void performSave() {
      Provider.of<TransactionProvider>(context, listen: false)
          .setBudget(_selectedCategory, limit);
      _limitController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديد ميزانية لـ $_selectedCategory بنجاح! 🎯', style: const TextStyle(fontFamily: 'Amiri')),
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
                  const Text(
                    'تحديد ميزانية لفئة',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'اختر الفئة',
                      labelStyle: const TextStyle(fontFamily: 'Amiri'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: CategoryModel.defaultCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.name,
                        child: Row(
                          children: [
                            Icon(cat.icon, color: cat.color),
                            const SizedBox(width: 10),
                            Text(cat.name, style: const TextStyle(fontFamily: 'Amiri')),
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
                      labelText: 'الحد الأقصى (الميزانية المسموحة)',
                      labelStyle: const TextStyle(fontFamily: 'Amiri'),
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
                    child: const Text('حفظ الميزانية', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الميزانيات الشهرية', style: TextStyle(fontFamily: 'Amiri')),
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
                    const Text(
                      'لم تقم بتحديد أي ميزانيات بعد.\nحدد حدوداً لصرفك اليومي لتتحكم في مصاريفك!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.5, fontFamily: 'Amiri', color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddBudgetDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('تحديد ميزانية الآن', style: TextStyle(fontFamily: 'Amiri')),
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
                                budget.categoryName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
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
                            'المستهلك: ${budget.spentAmount.toStringAsFixed(2)} $currency',
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: isOverrun ? Colors.red : Colors.black87,
                            ),
                          ),
                          Text(
                            'الحد: ${budget.limitAmount.toStringAsFixed(2)} $currency',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      if (isOverrun) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ لقد تجاوزت الميزانية المحددة لهذه الفئة!',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                        ),
                      ] else if (isWarning) ...[
                        const SizedBox(height: 8),
                        const Text(
                          '⚠️ اقتربت من تجاوز ميزانية هذه الفئة (أكثر من 80%)',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
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
