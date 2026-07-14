import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/category_model.dart';
import '../core/utils/haptic_helper.dart';
import '../core/utils/audio_helper.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _inputController = TextEditingController();
  String _parsedTitle = '';
  double _parsedAmount = 0.0;
  bool _isExpense = true;
  String _suggestedCategory = 'أخرى';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _parseInput(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _parsedTitle = '';
        _parsedAmount = 0.0;
        _isExpense = true;
        _suggestedCategory = 'أخرى';
      });
      return;
    }

    // Extract numbers (integer or decimal)
    final numRegExp = RegExp(r'\d+(\.\d+)?');
    final match = numRegExp.firstMatch(input);
    
    double amount = 0.0;
    if (match != null) {
      amount = double.tryParse(match.group(0)!) ?? 0.0;
    }

    // Extract non-number text as title
    String title = input.replaceAll(numRegExp, '').trim();
    title = title.replaceAll(RegExp(r'\s+'), ' '); // Clean double spaces

    if (title.isEmpty) {
      title = 'مصروف سريع';
    }

    // Simple Smart Category & Income Classification
    bool isExpense = true;
    String category = 'أخرى';

    final text = title.toLowerCase();
    
    if (text.contains('راتب') || text.contains('قبض') || text.contains('دخل') || text.contains('ربح') || text.contains('جاني')) {
      isExpense = false;
    }

    if (text.contains('أكل') || text.contains('اكل') || text.contains('غداء') || text.contains('عشاء') || text.contains('فطور') || text.contains('مطعم') || text.contains('قهوة') || text.contains('شاي') || text.contains('كافيه')) {
      category = 'طعام وشراب';
    } else if (text.contains('مواصلات') || text.contains('بنزين') || text.contains('أوبر') || text.contains('اوبر') || text.contains('تاكسي') || text.contains('تكس') || text.contains('سيارة') || text.contains('عربية') || text.contains('مترو')) {
      category = 'مواصلات';
    } else if (text.contains('شراء') || text.contains('لبس') || text.contains('هدوم') || text.contains('تسوق') || text.contains('سوبرماركت') || text.contains('طلب الطلبات')) {
      category = 'تسوق';
    } else if (text.contains('فاتورة') || text.contains('فواتير') || text.contains('كهرباء') || text.contains('مياه') || text.contains('إيجار') || text.contains('نت') || text.contains('انترنت')) {
      category = 'سكن وفواتير';
    } else if (text.contains('دواء') || text.contains('علاج') || text.contains('صيدلية') || text.contains('طبيب') || text.contains('دكتور') || text.contains('كشف')) {
      category = 'صحة وعلاج';
    } else if (text.contains('رحلة') || text.contains('سفر') || text.contains('سينما') || text.contains('خروج') || text.contains('فسحة')) {
      category = 'ترفيه وسفر';
    } else if (text.contains('مدرسة') || text.contains('كتاب') || text.contains('تعليم') || text.contains('جامعة') || text.contains('درس') || text.contains('كورس')) {
      category = 'تعليم';
    }

    setState(() {
      _parsedTitle = title;
      _parsedAmount = amount;
      _isExpense = isExpense;
      _suggestedCategory = category;
    });
  }

  void _submit() {
    if (_parsedAmount <= 0) return;

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(
      title: _parsedTitle,
      amount: _parsedAmount,
      date: DateTime.now(),
      isExpense: _isExpense,
      categoryName: _suggestedCategory,
    );

    // Award +5 coins for recording a transaction
    Provider.of<GamificationProvider>(context, listen: false).addCoins(5);

    HapticHelper.successTap();
    AudioHelper.playCashSound();
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💰 "سجلتها... متقلقش! تم حفظ $_parsedTitle بقيمة $_parsedAmount"',
          style: const TextStyle(fontFamily: 'Amiri'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currency = provider.preferredCurrency;

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
            'إضافة سريعة بنقرة واحدة ⚡',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 8),
          const Text(
            'اكتب مثلاً: "120 قهوة" أو "350 بنزين" أو "6000 راتب"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _inputController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'اكتب هنا...',
              hintStyle: const TextStyle(fontFamily: 'Amiri'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              prefixIcon: const Icon(Icons.bolt, color: Colors.amber),
            ),
            onChanged: _parseInput,
          ),
          const SizedBox(height: 16),
          
          // Preview of Parse Results
          if (_parsedAmount > 0)
            Card(
              color: _isExpense ? Colors.red.withOpacity(0.05) : Colors.green.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isExpense ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العنوان المكتشف: $_parsedTitle',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('الفئة المقترحة: '),
                            Chip(
                              label: Text(_suggestedCategory, style: const TextStyle(fontSize: 12, fontFamily: 'Amiri')),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            )
                          ],
                        ),
                      ],
                    ),
                    Text(
                      '${_isExpense ? "-" : "+"}$_parsedAmount $currency',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isExpense ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _parsedAmount > 0 ? _submit : null,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: _isExpense ? Colors.red.shade700 : Colors.green.shade700,
              disabledBackgroundColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              'حفظ المعاملة السريعة',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
