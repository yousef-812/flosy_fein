import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../widgets/ad_native_widget.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // 0: All, 1: Expenses Only, 2: Income Only
  int _filterIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final currency = provider.preferredCurrency;
        
        // Apply filters
        var filteredList = provider.transactions.where((tx) {
          final matchesSearch = tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              tx.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
          
          if (!matchesSearch) return false;

          if (_filterIndex == 1) return tx.isExpense;
          if (_filterIndex == 2) return !tx.isExpense;
          return true;
        }).toList();

        // Mix native ads into history list
        final itemsWithAds = <dynamic>[];
        const int adInterval = 4;
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
            title: const Text('سجل العمليات', style: TextStyle(fontFamily: 'Amiri')),
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
                    hintText: 'البحث عن معاملة...',
                    hintStyle: const TextStyle(fontFamily: 'Amiri'),
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

              // Filter row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                child: itemsWithAds.isEmpty
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
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20.0),
                              decoration: BoxDecoration(
                                color: Colors.red.shade800,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              provider.deleteTransaction(tx.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم حذف المعاملة بنجاح! 🗑️', style: TextStyle(fontFamily: 'Amiri')),
                                ),
                              );
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
}
