import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/language_provider.dart';

class WidgetPreview extends StatelessWidget {
  final TransactionProvider provider;

  const WidgetPreview({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currency = provider.preferredCurrency;
    final balance = provider.totalBalance;
    
    // Get last transaction
    final lastTx = provider.transactions.isNotEmpty ? provider.transactions.first : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Widget Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.savings, color: Colors.blue, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    languageProvider.translate('app_name'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  languageProvider.translate('widget_phone_label'),
                  style: const TextStyle(fontSize: 8, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Balance Area
          Text(
            languageProvider.translate('net_budget_label'),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            '${balance.toStringAsFixed(2)} $currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),

          // Last Transaction Mockup
          if (lastTx != null) ...[
            Text(
              languageProvider.translate('last_transaction_label'),
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lastTx.title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${lastTx.isExpense ? "-" : "+"}${lastTx.amount.toStringAsFixed(1)} $currency',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: lastTx.isExpense ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              languageProvider.translate('no_transactions_yet'),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Interactive Shortcut Mock Button
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  languageProvider.translate('widget_quick_add'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
