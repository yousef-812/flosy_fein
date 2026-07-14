import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../core/utils/haptic_helper.dart';

class FinancialPetWidget extends StatefulWidget {
  const FinancialPetWidget({super.key});

  @override
  State<FinancialPetWidget> createState() => _FinancialPetWidgetState();
}

class _FinancialPetWidgetState extends State<FinancialPetWidget> {
  bool _showHearts = false;

  void _feedPet(GamificationProvider gamification) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);
    if (gamification.userCoins >= 10) {
      HapticHelper.successTap();
      await gamification.addCoins(-10);
      setState(() {
        _showHearts = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.translate('feed_success_msg')),
          backgroundColor: Colors.pink,
        ),
      );
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showHearts = false;
          });
        }
      });
    } else {
      HapticHelper.heavyTap();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lp.translate('feed_fail_msg')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transProvider = Provider.of<TransactionProvider>(context);
    final gamification = Provider.of<GamificationProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    final balance = transProvider.totalBalance;
    final income = transProvider.monthlyIncome;
    final expenses = transProvider.monthlyExpenses;

    // Check budget overrun status
    bool isOverrun = false;
    bool isWarning = false;
    for (var b in transProvider.budgets) {
      if (b.spentAmount >= b.limitAmount) {
        isOverrun = true;
      } else if (b.spentAmount >= b.limitAmount * 0.8) {
        isWarning = true;
      }
    }

    // Determine Pet State
    String petImagePath = 'assets/branding/mascot_happy.jpg';
    String petMood = languageProvider.translate('pet_mood_normal');
    String petComment = languageProvider.translate('pet_comment_normal');
    Color moodColor = Colors.blue;

    if (_showHearts) {
      petImagePath = 'assets/branding/mascot_happy.jpg';
      petMood = languageProvider.translate('pet_mood_fed');
      petComment = languageProvider.translate('pet_comment_fed');
      moodColor = Colors.pink;
    } else if (isOverrun) {
      petImagePath = 'assets/branding/mascot_sad.jpg';
      petMood = languageProvider.translate('pet_mood_overrun');
      petComment = languageProvider.translate('pet_comment_overrun');
      moodColor = Colors.red;
    } else if (isWarning) {
      petImagePath = 'assets/branding/mascot_worried.jpg';
      petMood = languageProvider.translate('pet_mood_warning');
      petComment = languageProvider.translate('pet_comment_warning');
      moodColor = Colors.orange;
    } else if (balance < 0) {
      petImagePath = 'assets/branding/mascot_sad.jpg';
      petMood = languageProvider.translate('pet_mood_negative');
      petComment = languageProvider.translate('pet_comment_negative');
      moodColor = Colors.purple;
    } else if (expenses < 0.3 * income && income > 0) {
      petImagePath = 'assets/branding/mascot_gold.jpg';
      petMood = languageProvider.translate('pet_mood_gold');
      petComment = languageProvider.translate('pet_comment_gold');
      moodColor = Colors.green;
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: moodColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Animated emoji pet
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: moodColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: Image.asset(
                          petImagePath,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (_showHearts)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Image.asset('assets/branding/heart.jpg', width: 22, height: 22),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Bubble and state
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            languageProvider.translate('pet_name'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: moodColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              petMood,
                              style: TextStyle(fontSize: 10, color: moodColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        petComment,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Feed control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      languageProvider.translate('coins_balance_label'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${gamification.userCoins}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/branding/coin.jpg', width: 12, height: 12, fit: BoxFit.cover),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _feedPet(gamification),
                  icon: const Icon(Icons.cookie, size: 16),
                  label: Text(languageProvider.translate('feed_btn'), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade50,
                    foregroundColor: Colors.pink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
