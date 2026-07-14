import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currency = provider.preferredCurrency;

    // Generate days of the selected month
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    // Align to Sunday-based grid (0 to 6)
    final startOffset = (startWeekday % 7);

    // List of transactions for the selected day
    final selectedDayTxs = provider.transactions.where((tx) =>
        tx.date.day == _selectedDate.day &&
        tx.date.month == _selectedDate.month &&
        tx.date.year == _selectedDate.year).toList();

    double dayIncome = 0;
    double dayExpense = 0;
    for (var tx in selectedDayTxs) {
      if (tx.isExpense) {
        dayExpense += tx.amount;
      } else {
        dayIncome += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('financial_calendar')),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Month Selector Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                    });
                  },
                ),
                Text(
                  '${languageProvider.translate('month_${_selectedDate.month}')} ${_selectedDate.year}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),

          // Weekdays Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(languageProvider.translate('day_sun'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_mon'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_tue'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_wed'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_thu'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_fri'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(languageProvider.translate('day_sat'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Days Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: daysInMonth + startOffset,
              itemBuilder: (context, index) {
                if (index < startOffset) {
                  return const SizedBox.shrink();
                }

                final dayNumber = index - startOffset + 1;
                final date = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
                final isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                // Check if date has transactions
                final hasTxs = provider.transactions.any((tx) =>
                    tx.date.day == dayNumber &&
                    tx.date.month == _selectedDate.month &&
                    tx.date.year == _selectedDate.year);

                final hasExpenses = provider.transactions.any((tx) =>
                    tx.isExpense &&
                    tx.date.day == dayNumber &&
                    tx.date.month == _selectedDate.month &&
                    tx.date.year == _selectedDate.year);

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1E88E5)
                          : hasTxs
                              ? (hasExpenses ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1))
                              : Theme.of(context).cardColor,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : Colors.grey.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (hasTxs && !isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: hasExpenses ? Colors.red : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 32),

          // Details Header for Selected Day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate('day_details')
                      .replaceFirst('{}', '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Row(
                  children: [
                    if (dayIncome > 0)
                      Text(
                        '+${dayIncome.toStringAsFixed(0)} $currency ',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    if (dayExpense > 0)
                      Text(
                        '-${dayExpense.toStringAsFixed(0)} $currency',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transactions list for Selected Day
          Expanded(
            child: selectedDayTxs.isEmpty
                ? Center(
                    child: Text(
                      languageProvider.translate('no_transactions_today'),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: selectedDayTxs.length,
                    itemBuilder: (context, index) {
                      final tx = selectedDayTxs[index];
                      final category = CategoryModel.defaultCategories.firstWhere(
                        (c) => c.name == tx.categoryName,
                        orElse: () => CategoryModel(name: tx.categoryName, icon: Icons.help, color: Colors.grey),
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category.color.withOpacity(0.2),
                            child: Icon(category.icon, color: category.color),
                          ),
                          title: Text(tx.title),
                          trailing: Text(
                            '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(2)} $currency',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.isExpense ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
