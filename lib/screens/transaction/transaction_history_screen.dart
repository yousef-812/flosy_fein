import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_native_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../core/utils/haptic_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0 = All, 1 = Expenses, 2 = Income
  bool _isLoading = true;

  int _viewMode = 0; // 0 = List View, 1 = Calendar View
  DateTime _calendarSelectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Simulate minor loading skeleton for premium feel
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int? _parseArabicMonth(String query) {
    final months = {
      'يناير': 1, 'يناير.': 1, 'january': 1, 'jan': 1,
      'فبراير': 2, 'february': 2, 'feb': 2,
      'مارس': 3, 'march': 3, 'mar': 3,
      'أبريل': 4, 'april': 4, 'apr': 4,
      'مايو': 5, 'may': 5,
      'يونيو': 6, 'june': 6, 'jun': 6,
      'يوليو': 7, 'july': 7, 'jul': 7,
      'أغسطس': 8, 'august': 8, 'aug': 8,
      'سبتمبر': 9, 'september': 9, 'sep': 9,
      'أكتوبر': 10, 'october': 10, 'oct': 10,
      'نوفمبر': 11, 'november': 11, 'nov': 11,
      'ديسمبر': 12, 'december': 12, 'dec': 12
    };

    final q = query.trim().toLowerCase();
    for (var key in months.keys) {
      if (key.contains(q) || q.contains(key)) {
        return months[key];
      }
    }
    return null;
  }

  void _showContextMenu(BuildContext context, TransactionModel tx, TransactionProvider provider, LanguageProvider lp) {
    HapticHelper.mediumTap();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  tx.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: Text(lp.translate('copy_title_context')),
                onTap: () {
                  Navigator.pop(context);
                  HapticHelper.lightTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lp.translate('title_copied_success'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat, color: Colors.green),
                title: Text(lp.translate('repeat_tx_today_context')),
                onTap: () {
                  provider.addTransaction(
                    title: tx.title,
                    amount: tx.amount,
                    date: DateTime.now(),
                    isExpense: tx.isExpense,
                    categoryName: tx.categoryName,
                  );
                  Navigator.pop(context);
                  HapticHelper.successTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lp.translate('tx_repeated_success'),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  lp.translate('delete_tx_context'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteWithUndo(context, tx, provider, lp);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteWithUndo(BuildContext context, TransactionModel tx, TransactionProvider provider, LanguageProvider lp) {
    provider.deleteTransaction(tx.id);
    HapticHelper.heavyTap();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(lp.translate('tx_deleted_undo_msg').replaceFirst('{}', tx.title)),
        action: SnackBarAction(
          label: lp.translate('undo_action_label'),
          textColor: Colors.amber,
          onPressed: () {
            provider.undoDelete();
            HapticHelper.successTap();
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currency = provider.preferredCurrency;

        // Calendar variables
        final firstDayOfMonth = DateTime(_calendarSelectedDate.year, _calendarSelectedDate.month, 1);
        final lastDayOfMonth = DateTime(_calendarSelectedDate.year, _calendarSelectedDate.month + 1, 0);
        final daysInMonth = lastDayOfMonth.day;
        final startWeekday = firstDayOfMonth.weekday;
        final startOffset = (startWeekday % 7);

        // List of transactions for the selected day in calendar view
        final selectedDayTxs = provider.transactions.where((tx) =>
            tx.date.day == _calendarSelectedDate.day &&
            tx.date.month == _calendarSelectedDate.month &&
            tx.date.year == _calendarSelectedDate.year).toList();

        double dayIncome = 0;
        double dayExpense = 0;
        for (var tx in selectedDayTxs) {
          if (tx.isExpense) {
            dayExpense += tx.amount;
          } else {
            dayIncome += tx.amount;
          }
        }

        // Smart Search Filtering for List View
        var filteredList = provider.transactions.where((tx) {
          final query = _searchQuery.trim().toLowerCase();
          if (query.isEmpty) return true;

          // 1. Value filters: ">500" or "<100"
          if (query.startsWith('>') && query.length > 1) {
            final val = double.tryParse(query.substring(1));
            if (val != null) {
              return tx.amount > val;
            }
          }
          if (query.startsWith('<') && query.length > 1) {
            final val = double.tryParse(query.substring(1));
            if (val != null) {
              return tx.amount < val;
            }
          }

          // 2. Month filter
          final monthIndex = _parseArabicMonth(_searchQuery);
          if (monthIndex != null) {
            return tx.date.month == monthIndex;
          }

          // 3. Normal Search Matching (Title & Category)
          final matchesSearch = tx.title.toLowerCase().contains(query) ||
              tx.categoryName.toLowerCase().contains(query) ||
              languageProvider.translateCategory(tx.categoryName).toLowerCase().contains(query);
          
          return matchesSearch;
        }).toList();

        // Apply tab index filter
        if (_filterIndex == 1) {
          filteredList = filteredList.where((tx) => tx.isExpense).toList();
        } else if (_filterIndex == 2) {
          filteredList = filteredList.where((tx) => !tx.isExpense).toList();
        }

        // Mix native ads into history list
        final itemsWithAds = <dynamic>[];
        const int adInterval = 5;
        for (int i = 0; i < filteredList.length; i++) {
          itemsWithAds.add(filteredList[i]);
          if ((i + 1) % adInterval == 0) {
            itemsWithAds.add('AD_PLACEHOLDER');
          }
        }
        if (itemsWithAds.isNotEmpty && itemsWithAds.last != 'AD_PLACEHOLDER') {
          itemsWithAds.add('AD_PLACEHOLDER');
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.translate('history_nav')),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Segmented Toggle Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    segments: [
                      ButtonSegment<int>(
                        value: 0,
                        icon: const Icon(Icons.list, size: 18),
                        label: Text(languageProvider.translate('history_calendar_toggle_list'), style: const TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(languageProvider.translate('history_calendar_toggle_cal'), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (newSelection) {
                      HapticHelper.lightTap();
                      setState(() {
                        _viewMode = newSelection.first;
                      });
                    },
                  ),
                ),
              ),

              // VIEW 0: LIST VIEW
              if (_viewMode == 0) ...[
                // Search Input Field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: languageProvider.translate('search_history_hint'),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FilterChip(
                        label: Text(languageProvider.translate('all_filter'), style: const TextStyle(fontSize: 12)),
                        selected: _filterIndex == 0,
                        onSelected: (_) => setState(() => _filterIndex = 0),
                      ),
                      FilterChip(
                        label: Text(languageProvider.translate('expenses_filter'), style: const TextStyle(color: Colors.red, fontSize: 12)),
                        selected: _filterIndex == 1,
                        onSelected: (_) => setState(() => _filterIndex = 1),
                      ),
                      FilterChip(
                        label: Text(languageProvider.translate('income_filter'), style: const TextStyle(color: Colors.green, fontSize: 12)),
                        selected: _filterIndex == 2,
                        onSelected: (_) => setState(() => _filterIndex = 2),
                      ),
                    ],
                  ),
                ),

                // Transaction list
                Expanded(
                  child: _isLoading
                      ? _buildSkeletonList()
                      : itemsWithAds.isEmpty
                          ? Center(
                              child: Text(
                                languageProvider.translate('no_matching_txs'),
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              itemCount: itemsWithAds.length,
                              itemBuilder: (context, index) {
                                final item = itemsWithAds[index];
                                if (item == 'AD_PLACEHOLDER') {
                                  return const AdNativeWidget();
                                }

                                final tx = item as TransactionModel;
                                final category = CategoryModel.defaultCategories.firstWhere(
                                  (c) => c.name == tx.categoryName,
                                  orElse: () => CategoryModel(name: tx.categoryName, icon: Icons.help, color: Colors.grey),
                                );

                                return Dismissible(
                                  key: Key(tx.id),
                                  direction: DismissDirection.horizontal,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    color: Colors.green.shade700,
                                    child: const Icon(Icons.repeat, color: Colors.white),
                                  ),
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20.0),
                                    color: Colors.red.shade800,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      // Swipe Right: Duplicate
                                      HapticHelper.successTap();
                                      provider.addTransaction(
                                        title: tx.title,
                                        amount: tx.amount,
                                        date: DateTime.now(),
                                        isExpense: tx.isExpense,
                                        categoryName: tx.categoryName,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            languageProvider.translate('tx_repeated_today_msg').replaceFirst('{}', tx.title),
                                          ),
                                        ),
                                      );
                                      return false;
                                    } else {
                                      // Swipe Left: Delete
                                      return true;
                                    }
                                  },
                                  onDismissed: (direction) {
                                    if (direction == DismissDirection.endToStart) {
                                      _deleteWithUndo(context, tx, provider, languageProvider);
                                    }
                                  },
                                  child: Card(
                                    elevation: 0,
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: category.color.withOpacity(0.15),
                                        child: Icon(category.icon, color: category.color, size: 20),
                                      ),
                                      title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      subtitle: Text(
                                        '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      trailing: Text(
                                        '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(0)} $currency',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: tx.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      onLongPress: () => _showContextMenu(context, tx, provider, languageProvider),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],

              // VIEW 1: CALENDAR VIEW
              if (_viewMode == 1) ...[
                // Month Selector Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 18),
                        onPressed: () {
                          HapticHelper.lightTap();
                          setState(() {
                            _calendarSelectedDate = DateTime(_calendarSelectedDate.year, _calendarSelectedDate.month - 1, 1);
                          });
                        },
                      ),
                      Text(
                        '${languageProvider.translate('month_${_calendarSelectedDate.month}')} ${_calendarSelectedDate.year}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        onPressed: () {
                          HapticHelper.lightTap();
                          setState(() {
                            _calendarSelectedDate = DateTime(_calendarSelectedDate.year, _calendarSelectedDate.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Weekdays Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(languageProvider.translate('day_sun'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_mon'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_tue'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_wed'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_thu'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_fri'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                      Text(languageProvider.translate('day_sat'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),

                // Days Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: daysInMonth + startOffset,
                    itemBuilder: (context, index) {
                      if (index < startOffset) {
                        return const SizedBox.shrink();
                      }

                      final dayNumber = index - startOffset + 1;
                      final date = DateTime(_calendarSelectedDate.year, _calendarSelectedDate.month, dayNumber);
                      final isSelected = date.day == _calendarSelectedDate.day &&
                          date.month == _calendarSelectedDate.month &&
                          date.year == _calendarSelectedDate.year;

                      final dayTxs = provider.transactions.where((tx) =>
                          tx.date.day == dayNumber &&
                          tx.date.month == _calendarSelectedDate.month &&
                          tx.date.year == _calendarSelectedDate.year).toList();

                      final hasTxs = dayTxs.isNotEmpty;
                      final hasExpenses = dayTxs.any((tx) => tx.isExpense);

                      return InkWell(
                        onTap: () {
                          HapticHelper.lightTap();
                          setState(() {
                            _calendarSelectedDate = date;
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
                                  : Colors.grey.withOpacity(0.15),
                              width: isSelected ? 1.5 : 1,
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
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              if (hasTxs && !isSelected)
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 2),
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
                const Divider(height: 20),

                // Selected Day Header Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.translate('day_details')
                            .replaceFirst('{}', '${_calendarSelectedDate.day}/${_calendarSelectedDate.month}/${_calendarSelectedDate.year}'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Row(
                        children: [
                          if (dayIncome > 0)
                            Text(
                              '+${dayIncome.toStringAsFixed(0)} $currency ',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          if (dayExpense > 0)
                            Text(
                              '-${dayExpense.toStringAsFixed(0)} $currency',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Selected Day Transaction List
                Expanded(
                  child: selectedDayTxs.isEmpty
                      ? Center(
                          child: Text(
                            languageProvider.translate('no_transactions_today'),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
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
                            return Dismissible(
                              key: Key(tx.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20.0),
                                color: Colors.red.shade800,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                _deleteWithUndo(context, tx, provider, languageProvider);
                              },
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.withOpacity(0.12)),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: category.color.withOpacity(0.15),
                                    child: Icon(category.icon, color: category.color, size: 20),
                                  ),
                                  title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  trailing: Text(
                                    '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(0)} $currency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tx.isExpense ? Colors.red.shade700 : Colors.green.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  onLongPress: () => _showContextMenu(context, tx, provider, languageProvider),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],

              // 4. Always show Banner Ad at the bottom of History Screen
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: AdBannerWidget(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.12)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                SkeletonLoader(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(width: 100, height: 16),
                    SizedBox(height: 8),
                    SkeletonLoader(width: 60, height: 12),
                  ],
                ),
                Spacer(),
                SkeletonLoader(width: 80, height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
