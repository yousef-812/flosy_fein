import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/challenge_model.dart';
import '../../core/utils/haptic_helper.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<TransactionProvider>(context, listen: false)
          .evaluateChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('challenges_title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider =
                  Provider.of<TransactionProvider>(context, listen: false);
              await provider.resetChallenges();
              HapticHelper.mediumTap();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    languageProvider.translate('challenges_reset_success'),
                  ),
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
            return Center(
              child: Text(
                languageProvider.translate('no_challenges_now'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              final daysLeft = _daysLeft(challenge);
              final status = _statusFor(challenge, languageProvider);
              final displayTitle =
                  languageProvider.translate('${challenge.id}_title');
              final displayDescription =
                  languageProvider.translate('${challenge.id}_desc');

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: status.color.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              status.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: status.color,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayDescription,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(status.icon, color: status.color, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              challenge.isCompleted
                                  ? languageProvider
                                      .translate('saving_goal_great')
                                  : challenge.isFailed
                                      ? languageProvider
                                          .translate('challenge_failed_msg')
                                      : languageProvider
                                          .translate('challenge_days_left')
                                          .replaceFirst('{}', '$daysLeft')
                                          .replaceFirst(
                                            '{}',
                                            '${challenge.durationDays}',
                                          ),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  int _daysLeft(ChallengeModel challenge) {
    final start = DateTime(
      challenge.startDate.year,
      challenge.startDate.month,
      challenge.startDate.day,
    );
    final end = start.add(Duration(days: challenge.durationDays));
    if (!DateTime.now().isBefore(end)) return 0;

    final remaining = end.difference(DateTime.now());
    return (remaining.inHours / 24).ceil().clamp(0, challenge.durationDays);
  }

  _ChallengeStatus _statusFor(
    ChallengeModel challenge,
    LanguageProvider languageProvider,
  ) {
    if (challenge.isCompleted) {
      return _ChallengeStatus(
        color: Colors.green,
        text: languageProvider.translate('challenge_status_completed'),
        icon: Icons.stars,
      );
    }

    if (challenge.isFailed) {
      return _ChallengeStatus(
        color: Colors.red,
        text: languageProvider.translate('challenge_status_failed'),
        icon: Icons.cancel,
      );
    }

    return _ChallengeStatus(
      color: Colors.blue,
      text: languageProvider.translate('challenge_status_ongoing'),
      icon: Icons.hourglass_empty,
    );
  }
}

class _ChallengeStatus {
  final Color color;
  final String text;
  final IconData icon;

  const _ChallengeStatus({
    required this.color,
    required this.text,
    required this.icon,
  });
}
