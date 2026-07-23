import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/language_provider.dart';
import '../../core/utils/ad_helper.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/audio_helper.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/widget_preview.dart';
import '../../widgets/ad_banner_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = [
    'ج.م',
    'ر.س',
    'د.إ',
    'د.ك',
    'د.أ',
    'ج.س',
    'دولار',
  ];

  String _getCurrencyLabel(String key, LanguageProvider languageProvider) {
    switch (key) {
      case 'ج.م':
        return languageProvider.translate('currency_egp');
      case 'ر.س':
        return languageProvider.translate('currency_sar');
      case 'د.إ':
        return languageProvider.translate('currency_aed');
      case 'د.ك':
        return languageProvider.translate('currency_kwd');
      case 'د.أ':
        return languageProvider.translate('currency_jod');
      case 'ج.س':
        return languageProvider.translate('currency_sdg');
      case 'دولار':
        return languageProvider.translate('currency_usd');
      default:
        return key;
    }
  }

  void _showPremiumComingSoon(LanguageProvider languageProvider) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            languageProvider.translate('premium_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            languageProvider.isArabic
                ? 'الشراء غير متاح حاليًا. سيتم تفعيله بعد ربط التطبيق بنظام الدفع الرسمي والتحقق من عمليات الشراء.'
                : 'Purchasing is not available yet. It will be enabled after official store billing and purchase verification are configured.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(languageProvider.translate('close')),
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
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber.shade700.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.amber, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        languageProvider.translate('premium_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AdHelper.isPremiumUser
                        ? languageProvider.translate('premium_body_active')
                        : languageProvider.isArabic
                            ? 'النسخة الذهبية ستتوفر بعد ربط الدفع الرسمي. لا توجد حاليًا أي عملية شراء تجريبية أو تفعيل مجاني.'
                            : 'Premium will be available after official billing is connected. Mock purchases and free activation are disabled.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (!AdHelper.isPremiumUser) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _showPremiumComingSoon(languageProvider),
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        languageProvider.isArabic
                            ? 'قريبًا بعد ربط الدفع'
                            : 'Coming after billing setup',
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
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: Text(
                languageProvider.translate('dark_mode'),
                style: const TextStyle(fontSize: 18),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                HapticHelper.lightTap();
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: Text(
                languageProvider.translate('interactive_sounds'),
                style: const TextStyle(fontSize: 18),
              ),
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
          Card(
            child: ListTile(
              title: Text(
                languageProvider.translate('preferred_currency'),
                style: const TextStyle(fontSize: 18),
              ),
              trailing: DropdownButton<String>(
                value: transactionProvider.preferredCurrency,
                underline: const SizedBox.shrink(),
                items: _currencies.map((currency) {
                  return DropdownMenuItem<String>(
                    value: currency,
                    child: Text(
                      _getCurrencyLabel(currency, languageProvider),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  HapticHelper.lightTap();
                  transactionProvider.setPreferredCurrency(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(
                languageProvider.translate('app_language'),
                style: const TextStyle(fontSize: 18),
              ),
              trailing: DropdownButton<String>(
                value: languageProvider.currentLanguage,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'ar',
                    child: Text(
                      'العربية (Arabic)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(
                      'English',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  HapticHelper.lightTap();
                  languageProvider.changeLanguage(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(
                languageProvider.translate('reset_onboarding'),
                style: const TextStyle(fontSize: 18),
              ),
              trailing: const Icon(Icons.restart_alt, color: Colors.orange),
              onTap: () async {
                HapticHelper.heavyTap();
                await onboardingProvider.resetOnboarding();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text(
            languageProvider.translate('widget_preview_title'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: WidgetPreview(provider: transactionProvider)),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                languageProvider.translate('app_version'),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                languageProvider.translate('tagline'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
