import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/category_model.dart';
import '../../core/utils/haptic_helper.dart';

class WrappedScreen extends StatefulWidget {
  final TransactionProvider provider;

  const WrappedScreen({super.key, required this.provider});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  int _currentSlide = 0;
  Timer? _timer;
  double _progress = 0.0;
  final int _totalSlides = 4;

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
    final totalOps = widget.provider.transactions.length;

    // Calculate top category
    String topCategory = languageProvider.translate('cat_none');
    double maxCategorySpent = 0;
    final Map<String, double> categorySpent = {};
    for (var tx in widget.provider.transactions) {
      if (tx.isExpense) {
        categorySpent[tx.categoryName] = (categorySpent[tx.categoryName] ?? 0.0) + tx.amount;
      }
    }
    categorySpent.forEach((key, value) {
      if (value > maxCategorySpent) {
        maxCategorySpent = value;
        topCategory = key;
      }
    });

    // Calculate highest spending single transaction
    double highestTxAmount = 0.0;
    String highestTxTitle = languageProvider.translate('tx_none');
    for (var tx in widget.provider.transactions) {
      if (tx.isExpense && tx.amount > highestTxAmount) {
        highestTxAmount = tx.amount;
        highestTxTitle = tx.title;
      }
    }

    // Colors for different slides
    final List<Color> slideBgColors = [
      const Color(0xFF4A148C), // Deep Purple
      const Color(0xFF006064), // Deep Teal
      const Color(0xFF827717), // Deep Olive Gold
      const Color(0xFF1A237E), // Indigo/Midnight
    ];

    final translatedTopCategory = topCategory == languageProvider.translate('cat_none')
        ? topCategory
        : languageProvider.translateCategory(topCategory);

    return Scaffold(
      backgroundColor: slideBgColors[_currentSlide],
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
                        const Icon(Icons.slideshow, size: 80, color: Colors.white),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide0_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide0_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          languageProvider.translate('wrapped_slide0_ops').replaceFirst('{}', '$totalOps'),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ] else if (_currentSlide == 1) ...[
                        const Icon(Icons.shopping_bag, size: 80, color: Colors.cyanAccent),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide1_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide1_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          translatedTopCategory,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.translate('wrapped_slide1_spent')
                              .replaceFirst('{}', maxCategorySpent.toStringAsFixed(2))
                              .replaceFirst('{}', currency),
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ] else if (_currentSlide == 2) ...[
                        const Icon(Icons.money_off, size: 80, color: Colors.amberAccent),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide2_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide2_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          highestTxTitle,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.translate('wrapped_slide2_val')
                              .replaceFirst('{}', highestTxAmount.toStringAsFixed(2))
                              .replaceFirst('{}', currency),
                          style: const TextStyle(fontSize: 20, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ] else if (_currentSlide == 3) ...[
                        const Icon(Icons.emoji_events, size: 80, color: Colors.amberAccent),
                        const SizedBox(height: 24),
                        Text(
                          languageProvider.translate('wrapped_slide3_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            children: [
                              Text('${languageProvider.translate("app_name")} - 2026', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text(
                                languageProvider.translate('wrapped_slide3_item1').replaceFirst('{}', '$totalOps'),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                languageProvider.translate('wrapped_slide3_item2').replaceFirst('{}', translatedTopCategory),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                languageProvider.translate('wrapped_slide3_item3').replaceFirst('{}', highestTxTitle),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticHelper.successTap();
                            final shareText = "${languageProvider.translate('wrapped_slide0_title')}\n"
                                "${languageProvider.translate('wrapped_slide3_item1').replaceFirst('{}', '$totalOps')}\n"
                                "${languageProvider.translate('wrapped_slide3_item2').replaceFirst('{}', translatedTopCategory)}\n"
                                "${languageProvider.translate('wrapped_slide3_item3').replaceFirst('{}', highestTxTitle)}\n\n"
                                "Foloosy Fein 💰";
                            Share.share(shareText);
                          },
                          icon: const Icon(Icons.ios_share),
                          label: Text(languageProvider.translate('share_wrapped')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
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
}
