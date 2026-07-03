import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _limitController = TextEditingController();
  final _goalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _limitController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(budgetProvider.notifier)
        .setBudget(
          monthlyLimit: double.parse(_limitController.text.trim()),
          savingsGoal: double.parse(_goalController.text.trim()),
        );

    _limitController.clear();
    _goalController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget saved!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budget = ref.watch(budgetProvider);
    final expenses = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);

    final totalSpent = notifier.thisMonthTotal;
    final monthlyLimit = budget?.monthlyLimit ?? 0;
    final savingsGoal = budget?.savingsGoal ?? 0;
    final remaining = monthlyLimit - totalSpent;
    final savedSoFar = remaining > 0 ? remaining : 0.0;

    // ── Savings goal progress ──
    final savingsProgress = savingsGoal == 0
        ? 0.0
        : (savedSoFar / savingsGoal).clamp(0.0, 1.0);
    final savingsPercent = (savingsProgress * 100).toInt();

    // ── States ──
    final isOverBudget = remaining < 0 && monthlyLimit > 0;
    final isGoalReached = savingsPercent >= 100;
    final isWarning = savingsPercent > 0 && savingsPercent <= 30;
    final isZeroSavings = savingsPercent == 0 && monthlyLimit > 0;

    // ── Card color ──
    Color cardColor() {
      if (isOverBudget) return Colors.red.shade400;
      if (isZeroSavings) return Colors.red.shade400;
      if (isGoalReached) return AppColors.primary;
      if (isWarning) return Colors.orange.shade400;
      return AppColors.primary;
    }

    // ── Card title ──
    String cardTitle() {
      if (isOverBudget) return 'Over Budget!';
      if (isZeroSavings) return 'No Savings Yet!';
      if (isGoalReached) return 'Goal Reached! 🎉';
      if (isWarning) return 'Heads Up!';
      return 'Budget Remaining';
    }

    // ── Status message ──
    String statusMessage() {
      if (isOverBudget) {
        return 'You exceeded your monthly budget by ৳ ${remaining.abs().toStringAsFixed(2)}. Try to reduce spending!';
      }
      if (isZeroSavings) {
        return 'You have no savings this month. Try to spend less than your limit!';
      }
      if (isGoalReached) {
        return 'Amazing! You have reached your savings goal this month. Keep it up!';
      }
      if (isWarning) {
        return 'Looks like you are struggling with your budget this month. Slow down a little!';
      }
      return 'Great job! You are within your budget and saving well. Keep it up!';
    }

    // ── Message color ──
    Color messageColor() {
      if (isOverBudget) return Colors.red.shade700;
      if (isZeroSavings) return Colors.red.shade700;
      if (isGoalReached) return AppColors.primary;
      if (isWarning) return Colors.orange.shade700;
      return AppColors.primary;
    }

    // ── Message background ──
    Color messageBg() {
      if (isOverBudget) return Colors.red.shade50;
      if (isZeroSavings) return Colors.red.shade50;
      if (isGoalReached) return AppColors.surface;
      if (isWarning) return Colors.orange.shade50;
      return AppColors.surface;
    }

    // ── Message border ──
    Color messageBorder() {
      if (isOverBudget) return Colors.red.shade200;
      if (isZeroSavings) return Colors.red.shade200;
      if (isGoalReached) return AppColors.accent.withValues(alpha: 0.4);
      if (isWarning) return Colors.orange.shade200;
      return AppColors.accent.withValues(alpha: 0.4);
    }

    // ── Message icon ──
    IconData messageIcon() {
      if (isOverBudget) return Icons.warning_amber_rounded;
      if (isZeroSavings) return Icons.savings_outlined;
      if (isGoalReached) return Icons.check_circle_outline;
      if (isWarning) return Icons.trending_up;
      return Icons.check_circle_outline;
    }

    // ── Spending progress ──
    final spendingProgress = monthlyLimit == 0
        ? 0.0
        : (totalSpent / monthlyLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Budget',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (budget != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      'Clear Budget?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    content: const Text(
                      'This will remove your monthly limit and savings goal. Are you sure?',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(budgetProvider.notifier).clearBudget();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Budget cleared'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Yes, Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Budget status card ──
            if (budget != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardTitle(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳ ${remaining.abs().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Spending progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: spendingProgress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ৳ ${totalSpent.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Limit: ৳ ${monthlyLimit.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Status message ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: messageBg(),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: messageBorder()),
                ),
                child: Row(
                  children: [
                    Icon(messageIcon(), color: messageColor()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        statusMessage(),
                        style: TextStyle(color: messageColor(), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Savings goal card ──
              _sectionTitle('Savings Goal'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Target',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '৳ ${savingsGoal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Saved so far',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '৳ ${savedSoFar.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: savedSoFar > 0
                                ? AppColors.primary
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Savings progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: savingsProgress,
                        minHeight: 8,
                        backgroundColor: AppColors.accent.withValues(
                          alpha: 0.3,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isGoalReached
                              ? AppColors.primary
                              : isWarning
                              ? Colors.orange.shade400
                              : isZeroSavings
                              ? Colors.red.shade400
                              : AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$savingsPercent% of goal reached',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGoalReached
                            ? AppColors.primary
                            : isWarning
                            ? Colors.orange.shade600
                            : isZeroSavings
                            ? Colors.red.shade400
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Stats row ──
              _sectionTitle('This Month'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniStatCard(
                      label: 'Total Expenses',
                      value:
                          '${expenses.where((e) {
                            final now = DateTime.now();
                            return e.date.month == now.month && e.date.year == now.year;
                          }).length}',
                      icon: Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _miniStatCard(
                      label: 'Avg per day',
                      value:
                          '৳ ${(totalSpent / DateTime.now().day).toStringAsFixed(0)}',
                      icon: Icons.today,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],

            // ── Set / Update budget form ──
            _sectionTitle(budget == null ? 'Set Your Budget' : 'Update Budget'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _limitController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'Monthly Limit (৳)',
                        Icons.account_balance_wallet,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a limit';
                        if (double.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        if (double.parse(v) <= 0) {
                          return 'Must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'Savings Goal (৳)',
                        Icons.savings,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter a goal';
                        if (double.tryParse(v) == null) {
                          return 'Enter a valid number';
                        }
                        if (double.parse(v) < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveBudget,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          budget == null ? 'Set Budget' : 'Update Budget',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _miniStatCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
