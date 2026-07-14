import 'package:flutter/material.dart';

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
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.white,
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
              _buildJaggedEdge(),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'فلوسي فين',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      '« سجلني قبل ما تاكلني »',
                      style: TextStyle(
                        fontFamily: 'Amiri',
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
                    _buildRow('رقم الإيصال:', '#TX${date.millisecondsSinceEpoch.toString().substring(8)}'),
                    _buildRow('التاريخ:', '${date.day}/${date.month}/${date.year}'),
                    _buildRow('التوقيت:', '${date.hour}:${date.minute.toString().padLeft(2, "0")}'),
                    _buildRow('نوع العملية:', isExpense ? 'مصروف (صرف)' : 'دخل (ربح)'),
                    _buildRow('الفئة التابعة:', categoryName),
                    const SizedBox(height: 8),
                    const Text(
                      '--------------------------------------',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'القيمة الإجمالية',
                      style: TextStyle(
                        fontFamily: 'Amiri',
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
                     const Text(
                       '💰 "سجلتها... متقلقش، عيني عليها! 😉"',
                       style: TextStyle(
                         fontFamily: 'Amiri',
                         fontSize: 12,
                         color: Colors.grey,
                       ),
                     ),
                  ],
                ),
              ),

              // Bottom Control Buttons
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      label: const Text('مشاركة الإيصال', style: TextStyle(fontFamily: 'Amiri', color: Colors.blue)),
                      onPressed: () {
                        // Mock Share
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري تصدير الإيصال ومشاركته... 📤')),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text('إغلاق', style: TextStyle(fontFamily: 'Amiri', color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontFamily: 'Amiri', color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildJaggedEdge() {
    return Row(
      children: List.generate(
        16,
        (index) => Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
