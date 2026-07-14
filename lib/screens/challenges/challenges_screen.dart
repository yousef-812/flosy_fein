import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/challenge_model.dart';
import '../../core/utils/haptic_helper.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديات التوفير 💸', style: TextStyle(fontFamily: 'Amiri')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).resetChallenges();
              HapticHelper.mediumTap();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تمت إعادة تهيئة التحديات بنجاح!', style: TextStyle(fontFamily: 'Amiri')),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final challenges = provider.challenges;

          if (challenges.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد تحديات حالياً.',
                style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final ch = challenges[index];
              final now = DateTime.now();
              final difference = now.difference(ch.startDate).inDays;
              final daysLeft = (ch.durationDays - difference).clamp(0, ch.durationDays);

              // Automatically evaluate simple day challenges
              if (ch.id == 'challenge_3' && !ch.isCompleted && !ch.isFailed) {
                // Challenge 3 is "Day without expenses"
                // Check if yesterday or today has 0 expenses
                final today = DateTime(now.year, now.month, now.day);
                final todayTxs = provider.transactions.where((tx) =>
                    tx.isExpense &&
                    DateTime(tx.date.year, tx.date.month, tx.date.day) == today).toList();
                if (difference >= 1 && todayTxs.isEmpty) {
                  ch.isCompleted = true;
                  ch.save();
                } else if (todayTxs.isNotEmpty) {
                  // User spent money today
                  ch.isFailed = true;
                  ch.save();
                }
              }

              Color statusColor = Colors.blue;
              String statusText = 'جاري التحدي ⏳';
              IconData statusIcon = Icons.hourglass_empty;

              if (ch.isCompleted) {
                statusColor = Colors.green;
                statusText = 'ناجح 🏆';
                statusIcon = Icons.stars;
              } else if (ch.isFailed) {
                statusColor = Colors.red;
                statusText = 'فشل 💔';
                statusIcon = Icons.cancel;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ch.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            backgroundColor: statusColor,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ch.description,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'Amiri'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                ch.isCompleted
                                    ? 'أحسنت! وفرت فلوسك بنجاح 🎉'
                                    : ch.isFailed
                                        ? 'حظاً أوفر المرة القادمة! 🥺'
                                        : 'متبقي: $daysLeft يوم من أصل ${ch.durationDays}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                              ),
                            ],
                          ),
                          if (!ch.isCompleted && !ch.isFailed)
                            ElevatedButton(
                              onPressed: () {
                                // Manual verify trigger (for demo purposes)
                                setState(() {
                                  ch.isCompleted = true;
                                  ch.save();
                                });
                                HapticHelper.successTap();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🎉 مبروك! لقد نجحت في التحدي ووفرت فلوسك!', style: TextStyle(fontFamily: 'Amiri')),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: statusColor.withOpacity(0.2),
                                foregroundColor: statusColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('تحقق الآن', style: TextStyle(fontFamily: 'Amiri', fontSize: 12)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
