import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/category_model.dart';
import '../../core/utils/ad_helper.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/audio_helper.dart';
import '../../widgets/digital_receipt_dialog.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isExpense = true;
  String _selectedCategory = CategoryModel.defaultCategories.first.name;
  DateTime _selectedDate = DateTime.now();

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
    _titleController.dispose();
    _amountController.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text.trim());

    void performSave() {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.addTransaction(
        title: title,
        amount: amount,
        date: _selectedDate,
        isExpense: _isExpense,
        categoryName: _selectedCategory,
      );

      // Award +5 coins for recording a transaction
      Provider.of<GamificationProvider>(context, listen: false).addCoins(5);

      HapticHelper.successTap();
      AudioHelper.playCashSound();

      // Show digital receipt dialog, and navigate back on close
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => DigitalReceiptDialog(
          title: title,
          amount: amount,
          date: _selectedDate,
          isExpense: _isExpense,
          categoryName: _selectedCategory,
          currency: provider.preferredCurrency,
        ),
      ).then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }

    // Interstitial ad triggering with frequency capping
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة معاملة تفصيلية', style: TextStyle(fontFamily: 'Amiri')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expense / Income Toggle
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('مصروف (صرف)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                      ),
                      selected: _isExpense,
                      selectedColor: Colors.red.shade700,
                      labelStyle: TextStyle(color: _isExpense ? Colors.white : Colors.red.shade700),
                      onSelected: (selected) {
                        HapticHelper.lightTap();
                        setState(() {
                          _isExpense = true;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text('دخل (ربح)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
                      ),
                      selected: !_isExpense,
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(color: !_isExpense ? Colors.white : Colors.green.shade700),
                      onSelected: (selected) {
                        HapticHelper.lightTap();
                        setState(() {
                          _isExpense = false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  labelStyle: const TextStyle(fontSize: 16, fontFamily: 'Amiri'),
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.calculate_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'برجاء إدخال المبلغ';
                  }
                  if (double.tryParse(value.trim()) == null || double.parse(value.trim()) <= 0) {
                    return 'المبلغ غير صالح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Title Input Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'عنوان المعاملة (مثلا: غداء، راتب)',
                  labelStyle: const TextStyle(fontFamily: 'Amiri'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'برجاء كتابة عنوان للمصروف/الدخل';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Selector Header
              const Text(
                'اختر الفئة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
              ),
              const SizedBox(height: 12),

              // Category Grid View
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: CategoryModel.defaultCategories.length,
                itemBuilder: (context, index) {
                  final cat = CategoryModel.defaultCategories[index];
                  final isSelected = _selectedCategory == cat.name;
                  return InkWell(
                    onTap: () {
                      HapticHelper.lightTap();
                      setState(() {
                        _selectedCategory = cat.name;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? cat.color.withOpacity(0.2) 
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? cat.color : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(cat.icon, color: isSelected ? cat.color : Colors.grey),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'Amiri',
                              color: isSelected ? cat.color : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Date Picker Button
              ListTile(
                title: const Text('التاريخ', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () async {
                  HapticHelper.lightTap();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: _isExpense ? Colors.red.shade700 : Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'حفظ وعرض الإيصال 🧾',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
