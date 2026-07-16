import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/language_provider.dart';
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
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    _insights = PersonalityHelper.getDailyInsights(widget.transactions, widget.currency, lp.currentLanguage);
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
    final languageProvider = Provider.of<LanguageProvider>(context);
    _insights = PersonalityHelper.getDailyInsights(widget.transactions, widget.currency, languageProvider.currentLanguage);
    final quote = PersonalityHelper.getFunnyQuote(widget.transactions, languageProvider.currentLanguage);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.15), width: 1.2),
      ),
      elevation: 0,
      color: Colors.blue.withOpacity(0.04),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/branding/mascot_happy.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  languageProvider.translate('pet_name'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: Colors.blue.withOpacity(0.15)),
            const SizedBox(height: 12),

            // Mascot Quote Text
            Text(
              quote,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),

            // Animated Insight Slider
            if (_insights.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔮 ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _insights[_currentInsightIndex],
                          key: ValueKey<int>(_currentInsightIndex),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
