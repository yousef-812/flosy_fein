import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_native_widget.dart';
import '../../widgets/skeleton_loader.dart';
import '../../core/utils/haptic_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int _filterIndex = 0; // 0: All, 1: Expenses, 2: Income
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate skeleton loading delay for premium feel
    Future.delayed(const Duration(milliseconds: 700), () {
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

  // Parse Month names in Arabic
  int? _parseArabicMonth(String query) {
    final months = {
      'يناير': 1, 'فبراير': 2, 'مارس': 3, 'أبريل': 4, 'مايو': 5, 'يونيو': 6,
      'يوليو': 7, 'أغسطس': 8, 'سبتمبر': 9, 'أكتوبر': 10, 'نوفمبر': 11, 'ديسمبر': 12
    };
    for (var key in months.keys) {
      if (key.contains(query) || query.contains(key)) {
        return months[key];
      }
    }
    return null;
  }

  void _showContextMenu(BuildContext context, TransactionModel tx, TransactionProvider provider) {
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
                title: const Text('نسخ العنوان ماليًا', style: TextStyle(fontFamily: 'Amiri')),
                onTap: () {
                  // Copy to clipboard or copy title
                  Navigator.pop(context);
                  HapticHelper.lightTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ عنوان المعاملة!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.repeat, color: Colors.green),
                title: const Text('كرر العملية اليوم (سريعة)', style: TextStyle(fontFamily: 'Amiri')),
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
                    const SnackBar(content: Text('تم تكرار العملية بنجاح اليوم! 🔁', style: TextStyle(fontFamily: 'Amiri'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف المعاملة', style: TextStyle(fontFamily: 'Amiri', color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteWithUndo(context, tx, provider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteWithUndo(BuildContext context, TransactionModel tx, TransactionProvider provider) {
    provider.deleteTransaction(tx.id);
    HapticHelper.heavyTap();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف "${tx.title}" 🗑️', style: const TextStyle(fontFamily: 'Amiri')),
        action: SnackBarAction(
          label: 'تراجع (Undo)',
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
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currency = provider.preferredCurrency;
        
        // Smart Search Filtering
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

          // 2. Arabic Month filter (e.g. "فبراير")
          final monthIndex = _parseArabicMonth(_searchQuery);
          if (monthIndex != null) {
            return tx.date.month == monthIndex;
          }

          // 3. Normal Search Matching (Title & Category)
          final matchesSearch = tx.title.toLowerCase().contains(query) ||
              tx.categoryName.toLowerCase().contains(query);
          
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
            title: const Text('سجل العمليات المالي', style: TextStyle(fontFamily: 'Amiri')),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search input field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن "أكل" أو اكتب ">500" أو اسم الشهر...',
                    hintStyle: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterChip(
                      label: const Text('الكل', style: TextStyle(fontFamily: 'Amiri')),
                      selected: _filterIndex == 0,
                      onSelected: (_) => setState(() => _filterIndex = 0),
                    ),
                    FilterChip(
                      label: const Text('المصاريف', style: TextStyle(fontFamily: 'Amiri', color: Colors.red)),
                      selected: _filterIndex == 1,
                      onSelected: (_) => setState(() => _filterIndex = 1),
                    ),
                    FilterChip(
                      label: const Text('الأرباح والدخل', style: TextStyle(fontFamily: 'Amiri', color: Colors.green)),
                      selected: _filterIndex == 2,
                      onSelected: (_) => setState(() => _filterIndex = 2),
                    ),
                  ],
                ),
              ),

              // Transaction history list
              Expanded(
                child: _isLoading
                    ? _buildSkeletonList()
                    : itemsWithAds.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد معاملات مطابقة للبحث.',
                              style: TextStyle(fontSize: 16, fontFamily: 'Amiri', color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                                    // Swipe Right: Duplicate/Repeat transaction today
                                    HapticHelper.successTap();
                                    provider.addTransaction(
                                      title: tx.title,
                                      amount: tx.amount,
                                      date: DateTime.now(),
                                      isExpense: tx.isExpense,
                                      categoryName: tx.categoryName,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('تم تكرار "${tx.title}" اليوم! 🔁', style: const TextStyle(fontFamily: 'Amiri'))),
                                    );
                                    return false; // Don't dismiss item
                                  } else {
                                    // Swipe Left: Delete
                                    return true;
                                  }
                                },
                                onDismissed: (direction) {
                                  if (direction == DismissDirection.endToStart) {
                                    _deleteWithUndo(context, tx, provider);
                                  }
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: category.color.withOpacity(0.2),
                                      child: Icon(category.icon, color: category.color),
                                    ),
                                    title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      '${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${tx.isExpense ? "-" : "+"}${tx.amount.toStringAsFixed(2)} $currency',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tx.isExpense ? Colors.red : Colors.green,
                                        fontSize: 16,
                                      ),
                                    ),
                                    onLongPress: () => _showContextMenu(context, tx, provider),
                                  ),
                                ),
                              );
                            },
                          ),
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
        return const Card(
          margin: EdgeInsets.only(bottom: 8.0),
          child: Padding(
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
