import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/confetti_widget.dart';
import '../../../core/utils/haptic_helper.dart';

class StreakShopScreen extends StatefulWidget {
  const StreakShopScreen({super.key});

  @override
  State<StreakShopScreen> createState() => _StreakShopScreenState();
}

class _StreakShopScreenState extends State<StreakShopScreen> {
  bool _showConfetti = false;

  final List<Map<String, dynamic>> _shopItems = [
    {
      'id': 'theme_gold',
      'title': 'Royal Golden Theme 👑',
      'desc': 'Royal golden theme for the app!',
      'price': 100,
      'type': 'theme',
    },
    {
      'id': 'theme_autumn',
      'title': 'Warm Autumn Theme 🍂',
      'desc': 'Warm autumn colors theme!',
      'price': 50,
      'type': 'theme',
    },
    {
      'id': 'theme_rare_icons',
      'title': 'Rare Premium Icons 💎',
      'desc': 'Additional premium icons package!',
      'price': 30,
      'type': 'icons',
    },
  ];

  void _triggerConfetti() {
    setState(() {
      _showConfetti = true;
    });
    HapticHelper.successTap();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showConfetti = false;
        });
      }
    });
  }

  void _buyItem(GamificationProvider provider, String itemId, int price, String title, LanguageProvider lp) async {
    final success = await provider.buyTheme(itemId, price);
    if (success) {
      _triggerConfetti();
      try {
        FirebaseAnalytics.instance.logEvent(
          name: 'buy_theme',
          parameters: {
            'item_id': itemId,
            'price': price,
          },
        );
      } catch (e) {
        debugPrint('Firebase Analytics error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.translate('buy_success').replaceFirst('{}', title)),
          backgroundColor: Colors.amber,
        ),
      );
    } else {
      HapticHelper.heavyTap();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.translate('buy_fail')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamification = Provider.of<GamificationProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.translate('streak_shop')),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Coins Header Card
              Container(
                width: double.infinity,
                color: Colors.amber.withOpacity(0.12),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      languageProvider.translate('your_coins'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('assets/branding/coin.jpg', width: 32, height: 32, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${gamification.userCoins}',
                          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      languageProvider.translate('shop_motivation'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Shop items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _shopItems.length,
                  itemBuilder: (context, index) {
                    final item = _shopItems[index];
                    final itemId = item['id'] as String;
                    final isUnlocked = gamification.unlockedThemes.contains(itemId);
                    final isActive = gamification.activeTheme == itemId;

                    final itemTitle = languageProvider.translate(itemId + '_title');
                    final itemDesc = languageProvider.translate(itemId + '_desc');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isActive
                              ? Colors.amber
                              : Colors.grey.withOpacity(0.2),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  itemTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isUnlocked)
                                  Chip(
                                    label: Text(
                                      isActive 
                                          ? languageProvider.translate('theme_active') 
                                          : languageProvider.translate('theme_unlocked'),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: isActive ? Colors.amber.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  )
                                else
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset('assets/branding/coin.jpg', width: 16, height: 16, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${item['price']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemDesc,
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            // Buy or Activate Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isUnlocked)
                                  ElevatedButton(
                                    onPressed: isActive
                                        ? null
                                        : () {
                                            HapticHelper.lightTap();
                                            gamification.setActiveTheme(itemId);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(languageProvider.translate('activate_theme_btn')),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () => _buyItem(
                                      gamification,
                                      itemId,
                                      item['price'],
                                      itemTitle,
                                      languageProvider,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(languageProvider.translate('buy_now_btn')),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        ConfettiWidget(
          show: _showConfetti,
          onFinished: () {
            setState(() {
              _showConfetti = false;
            });
          },
        ),
      ],
    );
  }
}
