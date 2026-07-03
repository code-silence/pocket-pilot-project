import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import 'notification_screen.dart';
import 'insights_screen.dart';
import '../providers/budget_provider.dart';
import '../utils/page_transitions.dart';
import '../widgets/count_up_text.dart';
import '../providers/month_provider.dart';
import '../widgets/month_navigator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);

    final now = DateTime.now();
    final selectedMonth = ref.watch(monthProvider);
    final monthExpenses = notifier.expensesForMonth(selectedMonth);
    final totalSpent = notifier.totalForMonth(selectedMonth);
    final categoryTotals = notifier.categoryTotalsForMonth(selectedMonth);
    final topCategory = categoryTotals.isEmpty
        ? 'None'
        : categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
    final avgDaily = monthExpenses.isEmpty
        ? 0.0
        : totalSpent /
              (selectedMonth.month == now.month &&
                      selectedMonth.year == now.year
                  ? now.day
                  : DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                      0,
                    ).day);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'PocketPilot',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColors.primary,
                ),
              ),
              TextSpan(
                text: '  v1.1.0',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                SlideUpPageRoute(page: const InsightsScreen()), // ← changed
              );
            },
          ),

          //-----notification icon button----
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                SlideUpPageRoute(page: const NotificationScreen()), // ← changed
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello, User 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM yyyy').format(now),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: AppColors.surface,
                    radius: 24,
                    child: Icon(Icons.person, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Monthly summary card ──
              _monthlySummaryCard(ref, monthExpenses, totalSpent, now),

              const SizedBox(height: 16),

              // ── Month navigator ──
              const MonthNavigator(),

              // ── Total spent card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Spent This Month',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    CountUpText(
                      value: totalSpent,
                      prefix: '৳ ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statPill(
                          Icons.receipt_long,
                          '${monthExpenses.length} expenses',
                        ),
                        const SizedBox(width: 10),
                        _statPill(
                          Icons.today,
                          '৳ ${avgDaily.toStringAsFixed(0)}/day',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Quick stats row ──
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.trending_up,
                      label: 'Top Category',
                      value: topCategory,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.calendar_month,
                      label: 'This Month',
                      value: '${monthExpenses.length} items',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Category breakdown ──
              if (categoryTotals.isNotEmpty) ...[
                const Text(
                  'Spending by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...categoryTotals.entries.map((entry) {
                  final percent = totalSpent == 0
                      ? 0.0
                      : entry.value / totalSpent;
                  return _categoryBar(entry.key, entry.value, percent);
                }),
                const SizedBox(height: 24),
              ],

              // ── Recent expenses ──
              if (expenses.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Last ${expenses.take(3).length} entries',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...expenses.take(3).map((expense) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        _categoryIcon(expense.category),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM').format(expense.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '৳ ${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // ── Empty state ──
              if (expenses.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        Icons.savings_outlined,
                        size: 72,
                        color: AppColors.accent,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No expenses recorded yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap Add to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stat pill ──
  Widget _statPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Small stat card ──
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
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
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
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

  // ── Category progress bar ──
  Widget _categoryBar(String category, double amount, double percent) {
    final color = _categoryColor(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '৳ ${amount.toStringAsFixed(0)}  ${(percent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category icon ──
  Widget _categoryIcon(String category) {
    final color = _categoryColor(category);
    final icon = _categoryIconData(category);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Food':
        return AppColors.food;
      case 'Transport':
        return AppColors.transport;
      case 'Shopping':
        return AppColors.shopping;
      case 'Health':
        return AppColors.health;
      case 'Education':
        return AppColors.education;
      case 'Rent':
        return AppColors.rent;
      case 'Religious':
        return AppColors.religious;
      default:
        return AppColors.other;
    }
  }

  IconData _categoryIconData(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.favorite;
      case 'Education':
        return Icons.school;
      case 'Rent':
        return Icons.home;
      case 'Religious':
        return Icons
            .auto_awesome; // or Icons.mosque, depending on your preference
      default:
        return Icons.category;
    }
  }

  Widget _monthlySummaryCard(
    WidgetRef ref,
    List monthExpenses,
    double totalSpent,
    DateTime now,
  ) {
    final budget = ref.watch(budgetProvider);
    final monthlyLimit = budget?.monthlyLimit ?? 0;
    final savingsGoal = budget?.savingsGoal ?? 0;
    final remaining = monthlyLimit - totalSpent;
    final savedSoFar = remaining > 0 ? remaining : 0.0;
    final budgetProgress = monthlyLimit == 0
        ? 0.0
        : (totalSpent / monthlyLimit).clamp(0.0, 1.0);
    final savingsProgress = savingsGoal == 0
        ? 0.0
        : (savedSoFar / savingsGoal).clamp(0.0, 1.0);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft days left',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Stats row ──
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  label: 'Spent',
                  value: '৳ ${totalSpent.toStringAsFixed(0)}',
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'Saved',
                  value: '৳ ${savedSoFar.toStringAsFixed(0)}',
                  icon: Icons.savings,
                  color: AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _summaryItem(
                  label: 'Transactions',
                  value: '${monthExpenses.length}',
                  icon: Icons.receipt_long,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),

          // ── Budget progress ──
          if (monthlyLimit > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget used',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '${(budgetProgress * 100).toInt()}%  of  ৳ ${monthlyLimit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: budgetProgress,
                minHeight: 7,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  budgetProgress >= 1.0
                      ? Colors.red
                      : budgetProgress >= 0.7
                      ? Colors.orange
                      : AppColors.primary,
                ),
              ),
            ),
          ],

          // ── Savings progress ──
          if (savingsGoal > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Savings goal',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Text(
                  '${(savingsProgress * 100).toInt()}%  of  ৳ ${savingsGoal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: savingsProgress,
                minHeight: 7,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Summary item ──
  Widget _summaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
