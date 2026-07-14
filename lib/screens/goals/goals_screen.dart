import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/goal_model.dart';
import '../../widgets/confetti_widget.dart';
import '../../core/utils/haptic_helper.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _goalTitleController = TextEditingController();
  final _goalTargetController = TextEditingController();
  final _savingsAmountController = TextEditingController();
  bool _showConfetti = false;

  @override
  void dispose() {
    _goalTitleController.dispose();
    _goalTargetController.dispose();
    _savingsAmountController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    setState(() {
      _showConfetti = true;
    });
    HapticHelper.successTap();
  }

  void _showAddGoalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إضافة هدف ادخار جديد 🎯',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _goalTitleController,
                decoration: InputDecoration(
                  labelText: 'اسم الهدف (مثلاً: شراء هاتف، رحلة الصيف)',
                  labelStyle: const TextStyle(fontFamily: 'Amiri'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _goalTargetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ المستهدف (المطلوب تجميعه)',
                  labelStyle: const TextStyle(fontFamily: 'Amiri'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.monetization_on),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final title = _goalTitleController.text.trim();
                  final targetText = _goalTargetController.text.trim();
                  if (title.isEmpty || targetText.isEmpty) return;
                  final target = double.tryParse(targetText);
                  if (target == null || target <= 0) return;

                  Provider.of<TransactionProvider>(context, listen: false).addGoal(title, target);
                  _goalTitleController.clear();
                  _goalTargetController.clear();
                  Navigator.pop(context);
                  HapticHelper.mediumTap();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تمت إضافة الهدف بنجاح! 🎯', style: TextStyle(fontFamily: 'Amiri')),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('حفظ الهدف', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProgressDialog(GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16.0,
            16.0,
            16.0,
            MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ادخار لـ: ${goal.title} 💰',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _savingsAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'المبلغ المراد إضافته الآن للهدف',
                  labelStyle: const TextStyle(fontFamily: 'Amiri'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.add_card),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final amountText = _savingsAmountController.text.trim();
                  if (amountText.isEmpty) return;
                  final amount = double.tryParse(amountText);
                  if (amount == null || amount <= 0) return;

                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                  final isCompletedBefore = goal.currentAmount >= goal.targetAmount;
                  provider.updateGoalProgress(goal.id, amount);

                  _savingsAmountController.clear();
                  Navigator.pop(context);
                  HapticHelper.mediumTap();

                  // Check if goal is newly completed
                  final updatedGoal = provider.goals.firstWhere((g) => g.id == goal.id);
                  if (updatedGoal.currentAmount >= updatedGoal.targetAmount && !isCompletedBefore) {
                    _triggerConfetti();
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('🎉 مبروك يا وحش!', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
                        content: Text('حققت هدفك الادخاري: "${goal.title}" بنجاح! 🏆', style: const TextStyle(fontFamily: 'Amiri')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('عاش 🚀', style: TextStyle(fontFamily: 'Amiri', fontSize: 16)),
                          )
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تمت إضافة المدخرات للهدف! 💸', style: TextStyle(fontFamily: 'Amiri')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إضافة للرصيد', style: TextStyle(fontFamily: 'Amiri', fontSize: 18)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('أهداف الادخار', style: TextStyle(fontFamily: 'Amiri')),
            centerTitle: true,
          ),
          body: Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              final currency = provider.preferredCurrency;

              if (provider.goals.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.target, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          "مفيش أهداف ادخار مسجلة!\nحدد هدفك الآن ووفر فلوسك عشان تحققه 🎯",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, height: 1.5, fontFamily: 'Amiri', color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddGoalDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة أول هدف', style: TextStyle(fontFamily: 'Amiri')),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: provider.goals.length,
                itemBuilder: (context, index) {
                  final goal = provider.goals[index];
                  final percent = goal.targetAmount > 0
                      ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                      : 0.0;
                  final isCompleted = goal.currentAmount >= goal.targetAmount;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isCompleted
                          ? const BorderSide(color: Colors.green, width: 2)
                          : BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                                goal.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Amiri',
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => _showAddProgressDialog(goal),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      provider.deleteGoal(goal.id);
                                      HapticHelper.mediumTap();
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percent,
                              minHeight: 10,
                              color: isCompleted ? Colors.green : const Color(0xFF1E88E5),
                              backgroundColor: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المدخر: ${goal.currentAmount.toStringAsFixed(2)} $currency',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green : null,
                                ),
                              ),
                              Text(
                                'المستهدف: ${goal.targetAmount.toStringAsFixed(2)} $currency',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          if (isCompleted) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'تم تحقيق الهدف بنجاح! 🏆',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Amiri',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              if (provider.goals.isEmpty) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: _showAddGoalDialog,
                backgroundColor: const Color(0xFF1E88E5),
                child: const Icon(Icons.add, color: Colors.white),
              );
            },
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
