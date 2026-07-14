import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/utils/ad_helper.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/audio_helper.dart';
import '../../main.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/widget_preview.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = ['ج.م', 'ر.س', 'د.إ', 'د.ك', 'د.أ', 'ج.س', 'دولار'];

  String _getCurrencyLabel(String key, LanguageProvider lp) {
    switch (key) {
      case 'ج.م': return lp.translate('currency_egp');
      case 'ر.س': return lp.translate('currency_sar');
      case 'د.إ': return lp.translate('currency_aed');
      case 'د.ك': return lp.translate('currency_kwd');
      case 'د.أ': return lp.translate('currency_jod');
      case 'ج.س': return lp.translate('currency_sdg');
      case 'دولار': return lp.translate('currency_usd');
      default: return key;
    }
  }

  void _upgradeToPremium(LanguageProvider lp) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(lp.translate('premium_upgrade_btn'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            lp.translate('premium_upgrade_alert'),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () async {
                await AdHelper.setPremiumStatus(true);
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  HapticHelper.successTap();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lp.translate('premium_success_msg')),
                      backgroundColor: Colors.amber,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text(lp.translate('premium_buy_mock'), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lp.translate('cancel')),
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
    final onboardingProvider = Provider.of<OnboardingProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('settings')),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        languageProvider.translate('premium_title'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AdHelper.isPremiumUser
                        ? languageProvider.translate('premium_body_active')
                        : languageProvider.translate('premium_body_inactive'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (!AdHelper.isPremiumUser) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _upgradeToPremium(languageProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        languageProvider.translate('premium_upgrade_alert_btn'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            languageProvider.translate('general_preferences'),
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Theme Toggle
          Card(
            child: SwitchListTile(
              title: Text(languageProvider.translate('dark_mode'), style: const TextStyle(fontSize: 18)),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                HapticHelper.lightTap();
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 8),

          // Sound Toggle
          Card(
            child: SwitchListTile(
              title: Text(languageProvider.translate('interactive_sounds'), style: const TextStyle(fontSize: 18)),
              value: AudioHelper.isSoundEnabled,
              onChanged: (value) {
                HapticHelper.lightTap();
                setState(() {
                  AudioHelper.setSoundEnabled(value);
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Currency Selector
          Card(
            child: ListTile(
              title: Text(languageProvider.translate('preferred_currency'), style: const TextStyle(fontSize: 18)),
              trailing: DropdownButton<String>(
                value: transactionProvider.preferredCurrency,
                underline: const SizedBox(),
                items: _currencies.map((curr) {
                  return DropdownMenuItem<String>(
                    value: curr,
                    child: Text(_getCurrencyLabel(curr, languageProvider), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    HapticHelper.lightTap();
                    transactionProvider.setPreferredCurrency(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Language Selector Dropdown
          Card(
            child: ListTile(
              title: Text(languageProvider.translate('app_language'), style: const TextStyle(fontSize: 18)),
              trailing: DropdownButton<String>(
                value: languageProvider.currentLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'ar',
                    child: Text('العربية (Arabic)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text('English', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    HapticHelper.lightTap();
                    languageProvider.changeLanguage(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Reset Onboarding Option
          Card(
            child: ListTile(
              title: Text(languageProvider.translate('reset_onboarding'), style: const TextStyle(fontSize: 18)),
              trailing: const Icon(Icons.restart_alt, color: Colors.orange),
              onTap: () async {
                HapticHelper.heavyTap();
                await onboardingProvider.resetOnboarding();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Widget Preview Section
          Text(
            languageProvider.translate('widget_preview_title'),
            style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(child: WidgetPreview(provider: transactionProvider)),
          const SizedBox(height: 24),

          // About App Info
          Column(
            children: [
              Text(
                languageProvider.translate('app_version'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                languageProvider.translate('tagline'),
                style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          )
        ],
      ),
    );
  }
}
