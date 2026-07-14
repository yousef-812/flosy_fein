import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/transaction_provider.dart';

class SpendingStoryWidget extends StatefulWidget {
  final TransactionProvider provider;

  const SpendingStoryWidget({super.key, required this.provider});

  @override
  State<SpendingStoryWidget> createState() => _SpendingStoryWidgetState();
}

class _SpendingStoryWidgetState extends State<SpendingStoryWidget> {
  int _currentSlide = 0;
  Timer? _timer;
  double _progress = 0.0;
  final int _totalSlides = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.02; // Roughly 5 seconds total per slide
        } else {
          if (_currentSlide < _totalSlides - 1) {
            _currentSlide++;
            _progress = 0.0;
          } else {
            _timer?.cancel();
            Navigator.pop(context);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentSlide < _totalSlides - 1) {
      setState(() {
        _currentSlide++;
        _progress = 0.0;
      });
      _startTimer();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      setState(() {
        _currentSlide--;
        _progress = 0.0;
      });
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.provider.preferredCurrency;
    final income = widget.provider.monthlyIncome;
    final expenses = widget.provider.monthlyExpenses;

    // Calculate top category
    String topCategory = 'لا يوجد';
    double maxCategorySpent = 0;
    final Map<String, double> categorySpent = {};
    for (var tx in widget.provider.transactions) {
      if (tx.isExpense) {
        final now = DateTime.now();
        if (tx.date.month == now.month && tx.date.year == now.year) {
          categorySpent[tx.categoryName] = (categorySpent[tx.categoryName] ?? 0.0) + tx.amount;
        }
      }
    }
    categorySpent.forEach((key, value) {
      if (value > maxCategorySpent) {
        maxCategorySpent = value;
        topCategory = key;
      }
    });

    // Determine personality
    String personalityEmoji = '🛒';
    String personalityTitle = 'المتزن (Balanced)';
    String personalityDesc = 'تصرف بحكمة وتوازن بين متطلباتك ومدخراتك.';

    if (expenses < 0.4 * income && income > 0) {
      personalityEmoji = '🐿️';
      personalityTitle = 'السنجاب الموفر (The Saver)';
      personalityDesc = 'أنت حذر جداً في الصرف وتوفر جزءاً كبيراً من دخلك للمستقبل.';
    } else if (expenses > 0.9 * income && income > 0) {
      personalityEmoji = '🦁';
      personalityTitle = 'المغامر الجريء (The Risk Taker)';
      personalityDesc = 'تصرف كل ما في الجيب ليأتيك ما في الغيب! الحذر مطلوب.';
    } else if (topCategory == 'طعام وشراب') {
      personalityEmoji = '🍔';
      personalityTitle = 'عاشق الطعام (Food Lover)';
      personalityDesc = 'معدتك هي مركز قيادة مصاريفك! أغلب أموالك تذهب في الوجبات اللذيذة.';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx > width / 2) {
              _nextSlide();
            } else {
              _prevSlide();
            }
          },
          child: Stack(
            children: [
              // Slide Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentSlide == 0) ...[
                        const Icon(Icons.bar_chart, size: 80, color: Colors.blue),
                        const SizedBox(height: 24),
                        const Text(
                          'ملخص الشهر الحالي 📊',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 32),
                        _buildStoryCard(
                          title: 'إجمالي الدخل:',
                          value: '+${income.toStringAsFixed(2)} $currency',
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 16),
                        _buildStoryCard(
                          title: 'إجمالي المصاريف:',
                          value: '-${expenses.toStringAsFixed(2)} $currency',
                          color: Colors.redAccent,
                        ),
                      ] else if (_currentSlide == 1) ...[
                        const Icon(Icons.stars, size: 80, color: Colors.amber),
                        const SizedBox(height: 24),
                        const Text(
                          'أكثر فئة صرفت عليها 💥',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          topCategory,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amberAccent, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'بمجموع: ${maxCategorySpent.toStringAsFixed(2)} $currency',
                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                      ] else if (_currentSlide == 2) ...[
                        Text(
                          personalityEmoji,
                          style: const TextStyle(fontSize: 90),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'شخصيتك المالية 🔮',
                          style: TextStyle(fontSize: 24, color: Colors.white70, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          personalityTitle,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontFamily: 'Amiri'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          personalityDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5, fontFamily: 'Amiri'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Top Indicator Progress Bars
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: List.generate(_totalSlides, (index) {
                    double progressVal = 0.0;
                    if (index < _currentSlide) {
                      progressVal = 1.0;
                    } else if (index == _currentSlide) {
                      progressVal = _progress;
                    }
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        child: LinearProgressIndicator(
                          value: progressVal,
                          color: Colors.white,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Close Button
              Positioned(
                top: 32,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryCard({required String title, required String value, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.white70, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
