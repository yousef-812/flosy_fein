import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/language_provider.dart';
import '../core/utils/haptic_helper.dart';

class DigitalReceiptDialog extends StatelessWidget {
  final String title;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String categoryName;
  final String currency;

  const DigitalReceiptDialog({
    super.key,
    required this.title,
    required this.amount,
    required this.date,
    required this.isExpense,
    required this.categoryName,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Jagged Top Mockup
              _buildJaggedEdge(isDark),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      lp.translate('app_name'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      lp.translate('tagline'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '--------------------------------------',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _buildRow(lp.translate('receipt_id'), '#TX${date.millisecondsSinceEpoch.toString().substring(8)}', isDark),
                    _buildRow(lp.translate('date'), '${date.day}/${date.month}/${date.year}', isDark),
                    _buildRow(lp.translate('time'), '${date.hour}:${date.minute.toString().padLeft(2, "0")}', isDark),
                    _buildRow(lp.translate('transaction_type'), isExpense ? lp.translate('expense') : lp.translate('income'), isDark),
                    _buildRow(lp.translate('category'), categoryName, isDark),
                    const SizedBox(height: 8),
                    const Text(
                      '--------------------------------------',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lp.translate('total_amount'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${isExpense ? "-" : "+"}${amount.toStringAsFixed(2)} $currency',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lp.translate('receipt_comment'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Control Buttons
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Semantics(
                      button: true,
                      label: lp.translate('share_receipt'),
                      child: TextButton.icon(
                        icon: const Icon(Icons.share, color: Colors.blue),
                        label: Text(lp.translate('share_receipt'), style: const TextStyle(color: Colors.blue)),
                        onPressed: () {
                          HapticHelper.mediumTap();
                          final shareText = "${lp.translate('app_name')}\n"
                              "${lp.translate('receipt_id')} #TX${date.millisecondsSinceEpoch.toString().substring(8)}\n"
                              "${lp.translate('date')} ${date.day}/${date.month}/${date.year}\n"
                              "${lp.translate('transaction_type')} ${isExpense ? lp.translate('expense') : lp.translate('income')}\n"
                              "${lp.translate('category')} $categoryName\n"
                              "${lp.translate('total_amount')}: ${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} $currency\n\n"
                              "${lp.translate('receipt_comment')}";
                          Share.share(shareText);
                        },
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: lp.translate('close'),
                      child: TextButton(
                        child: Text(lp.translate('close'), style: const TextStyle(color: Colors.grey)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJaggedEdge(bool isDark) {
    return Row(
      children: List.generate(
        16,
        (index) => Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: index.isEven 
                  ? (isDark ? const Color(0xFF1E1E1E) : Colors.white) 
                  : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
