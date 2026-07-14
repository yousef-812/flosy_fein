import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/utils/ad_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = ['ج.م', 'ر.س', 'د.إ', 'د.ك', 'د.أ', 'ج.س', 'دولار'];

  void _upgradeToPremium() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ترقية للنسخة الذهبية', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          content: const Text(
            'احصل على تجربة خالية تماماً من الإعلانات لدعم استمرار التطبيق بلمسة واحدة!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Amiri'),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                await AdHelper.setPremiumStatus(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('مبروك! تم تفعيل النسخة الذهبية وإزالة الإعلانات بنجاح! 🏆', style: TextStyle(fontFamily: 'Amiri')),
                      backgroundColor: Colors.amber,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('شراء الآن (محاكاة)', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontFamily: 'Amiri')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(fontFamily: 'Amiri')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontFamily: 'Amiri')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Premium Gold Card
          Card(
            color: Colors.amber.shade700.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.amber, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'العضوية الذهبية (Premium)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri', color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AdHelper.isPremiumUser
                        ? 'أنت عضو ذهبي الآن! تم إيقاف جميع الإعلانات مدى الحياة! 🏆'
                        : 'تخلص من الإعلانات البينية والبنرات المزعجة بلمسة واحدة مدى الحياة.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Amiri'),
                  ),
                  if (!AdHelper.isPremiumUser) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _upgradeToPremium,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'شراء النسخة الذهبية 🚀',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'عام',
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
          ),
          const SizedBox(height: 8),

          // Theme Toggle
          Card(
            child: SwitchListTile(
              title: const Text('الوضع الداكن (Dark Mode)', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Currency Selector
          Card(
            child: ListTile(
              title: const Text('العملة المفضلة', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
              trailing: DropdownButton<String>(
                value: transactionProvider.preferredCurrency,
                underline: const SizedBox(),
                items: _currencies.map((curr) {
                  return DropdownMenuItem<String>(
                    value: curr,
                    child: Text(curr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    transactionProvider.setPreferredCurrency(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // About App Info
          const Column(
            children: [
              Text(
                'تطبيق فلوسي فين - النسخة 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '« سجلني قبل ما تاكلني »',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic, fontFamily: 'Amiri'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
