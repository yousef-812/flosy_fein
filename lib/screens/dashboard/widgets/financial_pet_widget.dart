import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../core/utils/haptic_helper.dart';

class FinancialPetWidget extends StatefulWidget {
  const FinancialPetWidget({super.key});

  @override
  State<FinancialPetWidget> createState() => _FinancialPetWidgetState();
}

class _FinancialPetWidgetState extends State<FinancialPetWidget> {
  bool _showHearts = false;

  void _feedPet(GamificationProvider gamification) async {
    if (gamification.userCoins >= 10) {
      HapticHelper.successTap();
      await gamification.addCoins(-10);
      setState(() {
        _showHearts = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🐷: هممم! طعمها حلو أوي، تسلم إيدك! 🥰 (+ حب)', style: TextStyle(fontFamily: 'Amiri')),
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
        const SnackBar(
          content: Text('معندكش عملات كافية لتأكيل الحصالة! 🥺 (مطلوب 10 عملات)', style: TextStyle(fontFamily: 'Amiri')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transProvider = Provider.of<TransactionProvider>(context);
    final gamification = Provider.of<GamificationProvider>(context);
    
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
    String petImagePath = 'assets/branding/mascot_happy.png';
    String petMood = 'متزن وواعي! 🙂';
    String petComment = 'مستقرين لحد دلوقتي.. بس متغفلنيش وسجل أول بأول! 😉';
    Color moodColor = Colors.blue;

    if (_showHearts) {
      petImagePath = 'assets/branding/mascot_happy.png';
      petMood = 'ممتن وشبعان! 🥰';
      petComment = 'يا سلام يا فنان.. طعامك طعمه دهب! كرشي بيشكرك! 🥰';
      moodColor = Colors.pink;
    } else if (isOverrun) {
      petImagePath = 'assets/branding/mascot_sad.png';
      petMood = 'بيعيط على الفلوس! 😢';
      petComment = 'يا لهوي! الميزانية طارت في الهواء يا فخر العرب! 😢💸';
      moodColor = Colors.red;
    } else if (isWarning) {
      petImagePath = 'assets/branding/mascot_worried.png';
      petMood = 'قلقان على محفظتك! 😟';
      petComment = 'بقولك إيه.. إحنا داخلين على منعطف خطر، اربط الحزام! 😟';
      moodColor = Colors.orange;
    } else if (balance < 0) {
      petImagePath = 'assets/branding/mascot_sad.png';
      petMood = 'تحت الصفر! 🥶';
      petComment = 'تحت الصفر؟ 🥶 كدا إحنا محتاجين معجزة مالية أو تقليل مصاريف فوري!';
      moodColor = Colors.purple;
    } else if (expenses < 0.3 * income && income > 0) {
      petImagePath = 'assets/branding/mascot_gold.png';
      petMood = 'سعيد وفخور بمدخراتك! 👑';
      petComment = 'يا سلام يا فنان.. القرش الأبيض بينفع في اليوم الأسود! 👑🏆';
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
                        child: Image.asset('assets/branding/heart.png', width: 22, height: 22),
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
                          const Text(
                            'الحصالة "فلوس" 💰',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Amiri'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: moodColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              petMood,
                              style: TextStyle(fontSize: 10, color: moodColor.shade700, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        petComment,
                        style: const TextStyle(fontSize: 13, height: 1.4, fontFamily: 'Amiri'),
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
                    const Text(
                      'رصيد عملاتك: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Amiri'),
                    ),
                    Text(
                      '${gamification.userCoins}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset('assets/branding/coin.png', width: 12, height: 12, fit: BoxFit.cover),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _feedPet(gamification),
                  icon: const Icon(Icons.cookie, size: 16),
                  label: const Text('أكله بـ 10 عملات', style: TextStyle(fontFamily: 'Amiri', fontSize: 12)),
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
