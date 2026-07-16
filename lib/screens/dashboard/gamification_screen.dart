import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/confetti_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/utils/ad_helper.dart';
import '../../core/utils/notification_helper.dart';
import 'widgets/financial_pet_widget.dart';
import '../shop/streak_shop_screen.dart';
import '../challenges/challenges_screen.dart';
import '../no_spend/no_spend_screen.dart';
import '../goals/goals_screen.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  bool _showCheckInConfetti = false;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadInterstitialAd() {
    if (kIsWeb || AdHelper.isPremiumUser) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Gamification InterstitialAd failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void _triggerCheckInConfetti() {
    setState(() {
      _showCheckInConfetti = true;
    });
    HapticHelper.successTap();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCheckInConfetti = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final gamification = Provider.of<GamificationProvider>(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(languageProvider.translate('pet_play_title')),
            centerTitle: true,
            actions: [
              // Coins shortcut to Shop
              GestureDetector(
                onTap: () {
                  HapticHelper.mediumTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StreakShopScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset('assets/branding/coin.jpg', width: 14, height: 14, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${gamification.userCoins}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Pet Mascot "Hassala"
                const FinancialPetWidget(),
                const SizedBox(height: 16),

                // 2. Daily Check-in Card (Shown only if available)
                if (gamification.canCheckInToday) ...[
                  Card(
                    elevation: 0,
                    color: Colors.amber.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.amber, width: 1.5),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset('assets/branding/gift.jpg', width: 36, height: 36, fit: BoxFit.cover),
                      ),
                      title: Text(
                        languageProvider.translate('daily_checkin_title'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        languageProvider.translate('daily_checkin_desc'),
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          final performClaim = () async {
                            final success = await gamification.claimDailyCheckIn();
                            if (success) {
                              _triggerCheckInConfetti();
                              CustomNotification.showPremium(
                                context,
                                languageProvider.translate('claim_success'),
                              );
                            }
                          };

                          if (_isAdLoaded && _interstitialAd != null && AdHelper.canShowInterstitial) {
                            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
                              onAdDismissedFullScreenContent: (ad) {
                                ad.dispose();
                                AdHelper.recordInterstitialShown();
                                performClaim();
                                _loadInterstitialAd();
                              },
                              onAdFailedToShowFullScreenContent: (ad, error) {
                                ad.dispose();
                                performClaim();
                                _loadInterstitialAd();
                              },
                            );
                            _interstitialAd!.show();
                          } else {
                            performClaim();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          languageProvider.translate('claim'),
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Play Navigation Sections
                Text(
                  languageProvider.translate('challenges_title'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Challenge Card
                _buildFunMenuCard(
                  context,
                  title: languageProvider.translate('challenges'),
                  subtitle: languageProvider.isArabic
                      ? "تنافس في تحديات توفير قهوتك ومصاريفك اليومية"
                      : "Compete in daily spending and coffee saving challenges",
                  icon: Icons.emoji_events,
                  color: Colors.teal,
                  screen: const ChallengesScreen(),
                ),
                const SizedBox(height: 12),

                // No Spend Calendar Card
                _buildFunMenuCard(
                  context,
                  title: languageProvider.translate('no_spend'),
                  subtitle: languageProvider.isArabic
                      ? "سجل أيامك الخالية من أي مصاريف وحافظ على رصيدك"
                      : "Track your zero-expense days and maintain your streak",
                  icon: Icons.calendar_month,
                  color: Colors.green,
                  screen: const NoSpendScreen(),
                ),
                const SizedBox(height: 12),

                // Savings Goals Card
                _buildFunMenuCard(
                  context,
                  title: languageProvider.translate('goals'),
                  subtitle: languageProvider.isArabic
                      ? "حدد أهدافك الادخارية واجمع مبالغ لشراء ما تريده"
                      : "Define your savings goals and collect money to buy what you want",
                  icon: Icons.track_changes,
                  color: Colors.orange,
                  screen: const GoalsScreen(),
                ),
                const SizedBox(height: 12),

                // Shop Card
                _buildFunMenuCard(
                  context,
                  title: languageProvider.translate('streak_shop'),
                  subtitle: languageProvider.isArabic
                      ? "استبدل عملاتك الذهبية بسمات وثيمات حصرية للتطبيق"
                      : "Redeem your gold coins for exclusive themes and colors",
                  icon: Icons.storefront,
                  color: Colors.amber.shade700,
                  screen: const StreakShopScreen(),
                ),

                const SizedBox(height: 16),
                // 4. Banner Ad in Gamification tab
                const AdBannerWidget(),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          show: _showCheckInConfetti,
          onFinished: () {
            setState(() {
              _showCheckInConfetti = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFunMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.12)),
      ),
      child: InkWell(
        onTap: () {
          HapticHelper.mediumTap();
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
