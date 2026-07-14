import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../../core/utils/haptic_helper.dart';

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
          _progress += 0.02; // 5 seconds per slide
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currency = widget.provider.preferredCurrency;

    // Calculate current month's income and expenses
    double income = 0;
    double expenses = 0;
    final now = DateTime.now();
    for (var tx in widget.provider.transactions) {
      if (tx.date.month == now.month && tx.date.year == now.year) {
        if (tx.isExpense) {
          expenses += tx.amount;
        } else {
          income += tx.amount;
        }
      }
    }

    // Calculate top category
    String topCategory = languageProvider.translate('cat_none');
    double maxCategorySpent = 0;
    final Map<String, double> categorySpent = {};
    for (var tx in widget.provider.transactions) {
      if (tx.isExpense) {
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
    String personalityTitle = languageProvider.translate('personality_balanced_title');
    String personalityDesc = languageProvider.translate('personality_balanced_desc');

    if (expenses < 0.4 * income && income > 0) {
      personalityEmoji = '🐿️';
      personalityTitle = languageProvider.translate('personality_saver_title');
      personalityDesc = languageProvider.translate('personality_saver_desc');
    } else if (expenses > 0.9 * income && income > 0) {
      personalityEmoji = '🦁';
      personalityTitle = languageProvider.translate('personality_risktaker_title');
      personalityDesc = languageProvider.translate('personality_risktaker_desc');
    } else if (topCategory == 'طعام وشراب') {
      personalityEmoji = '🍔';
      personalityTitle = languageProvider.translate('personality_foodlover_title');
      personalityDesc = languageProvider.translate('personality_foodlover_desc');
    }

    final translatedTopCategory = topCategory == languageProvider.translate('cat_none')
        ? topCategory
        : languageProvider.translateCategory(topCategory);

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
                        Text(
                          languageProvider.translate('monthly_summary_title'),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        _buildStoryCard(
                          title: languageProvider.translate('total_income_colon'),
                          value: '+${income.toStringAsFixed(2)} $currency',
                          color: Colors.greenAccent,
                        ),
                        const SizedBox(height: 16),
                        _buildStoryCard(
                          title: languageProvider.translate('total_expenses_colon'),
                          value: '-${expenses.toStringAsFixed(2)} $currency',
                          color: Colors.redAccent,
                        ),
                      ] else if (_currentSlide == 1) ...[
                        const Icon(Icons.stars, size: 80, color: Colors.amber),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('most_spent_category_title'),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          translatedTopCategory,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.translate('total_spent_amount')
                              .replaceFirst('{}', '${maxCategorySpent.toStringAsFixed(2)} $currency'),
                          style: const TextStyle(fontSize: 20, color: Colors.white70),
                        ),
                      ] else if (_currentSlide == 2) ...[
                        Text(
                          personalityEmoji,
                          style: const TextStyle(fontSize: 90),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.translate('financial_personality_title'),
                          style: const TextStyle(fontSize: 24, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          personalityTitle,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          personalityDesc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.5),
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
            style: const TextStyle(fontSize: 16, color: Colors.white70),
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
