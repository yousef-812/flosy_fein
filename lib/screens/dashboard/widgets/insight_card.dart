import 'dart:async';
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/utils/personality_helper.dart';

class InsightCard extends StatefulWidget {
  final List<TransactionModel> transactions;
  final String currency;

  const InsightCard({
    super.key,
    required this.transactions,
    required this.currency,
  });

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  int _currentInsightIndex = 0;
  Timer? _timer;
  late List<String> _insights;

  @override
  void initState() {
    super.initState();
    _loadInsights();
    _startTimer();
  }

  void _loadInsights() {
    _insights = PersonalityHelper.getDailyInsights(widget.transactions, widget.currency);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted && _insights.isNotEmpty) {
        setState(() {
          _currentInsightIndex = (_currentInsightIndex + 1) % _insights.length;
        });
      }
    });
  }

  @override
  void didUpdateWidget(InsightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInsights();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quote = PersonalityHelper.getFunnyQuote(widget.transactions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. "Foloos" Personality Bubble
        Card(
          color: Colors.blue.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Mascot Emoji or Avatar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💰', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),
                // Bubble Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'شخصية فلوس 💰:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                          fontFamily: 'Amiri',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quote,
                        style: const TextStyle(fontSize: 15, height: 1.4, fontFamily: 'Amiri'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Daily Insight Slides Card
        if (_insights.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _insights[_currentInsightIndex],
                        key: ValueKey<int>(_currentInsightIndex),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
