import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/constants.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final budget = ref.watch(budgetProvider);

    final totalSpent = notifier.thisMonthTotal;
    final categoryTotals = notifier.thisMonthCategoryTotals;
    final avgDaily = notifier.thisMonthExpenses.isEmpty
        ? 0.0
        : totalSpent / DateTime.now().day;
    final thisWeek = notifier.thisWeekTotal;
    final lastWeek = notifier.lastWeekTotal;
    final busiestDay = notifier.busiestDay;
    final totalTransactions = notifier.totalTransactionsThisMonth;
    final monthlyLimit = budget?.monthlyLimit ?? 0;

    final topCategory = categoryTotals.isEmpty
        ? 'None'
        : categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
    final topCategoryAmount = categoryTotals.isEmpty
        ? 0.0
        : categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .value;

    final weekDiff = thisWeek - lastWeek;
    final weekDiffPercent = lastWeek == 0
        ? 0.0
        : ((weekDiff / lastWeek) * 100).abs();

    // ── Generate smart tips ──
    final tips = _generateTips(
      totalSpent: totalSpent,
      monthlyLimit: monthlyLimit,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      avgDaily: avgDaily,
      thisWeek: thisWeek,
      lastWeek: lastWeek,
      totalTransactions: totalTransactions,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: totalSpent == 0
          ? _buildEmpty()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── This month overview ──
                  _sectionTitle('This Month Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _insightCard(
                          icon: Icons.calendar_today,
                          label: 'Avg per day',
                          value: '৳ ${avgDaily.toStringAsFixed(0)}',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _insightCard(
                          icon: Icons.receipt_long,
                          label: 'Transactions',
                          value: '$totalTransactions',
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _insightCard(
                          icon: Icons.star,
                          label: 'Busiest day',
                          value: busiestDay,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _insightCard(
                          icon: Icons.category,
                          label: 'Top category',
                          value: topCategory,
                          color: _categoryColor(topCategory),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Week comparison ──
                  _sectionTitle('Week Comparison'),
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
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _weekStat(
                              'Last week',
                              '৳ ${lastWeek.toStringAsFixed(0)}',
                              AppColors.textMuted,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: weekDiff > 0
                                    ? Colors.red.shade50
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: weekDiff > 0
                                      ? Colors.red.shade200
                                      : AppColors.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    weekDiff > 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 14,
                                    color: weekDiff > 0
                                        ? Colors.red
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${weekDiffPercent.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: weekDiff > 0
                                          ? Colors.red
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _weekStat(
                              'This week',
                              '৳ ${thisWeek.toStringAsFixed(0)}',
                              AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          weekDiff > 0
                              ? 'You are spending ${weekDiffPercent.toStringAsFixed(0)}% more than last week. Try to cut back!'
                              : weekDiff < 0
                              ? 'Great! You are spending ${weekDiffPercent.toStringAsFixed(0)}% less than last week!'
                              : 'Your spending is the same as last week.',
                          style: TextStyle(
                            fontSize: 13,
                            color: weekDiff > 0
                                ? Colors.red.shade600
                                : AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Category breakdown ──
                  if (categoryTotals.isNotEmpty) ...[
                    _sectionTitle('Category Breakdown'),
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
                        children: categoryTotals.entries.map((entry) {
                          final percent = totalSpent == 0
                              ? 0.0
                              : entry.value / totalSpent;
                          final color = _categoryColor(entry.key);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '৳ ${entry.value.toStringAsFixed(0)}  ${(percent * 100).toStringAsFixed(0)}%',
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
                                    minHeight: 6,
                                    backgroundColor: AppColors.accent
                                        .withValues(alpha: 0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Smart tips ──
                  if (tips.isNotEmpty) ...[
                    _sectionTitle('Smart Tips 💡'),
                    const SizedBox(height: 12),
                    ...tips.map((tip) => _tipCard(tip)),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ── Generate smart tips based on behavior ──
  List<Map<String, dynamic>> _generateTips({
    required double totalSpent,
    required double monthlyLimit,
    required String topCategory,
    required double topCategoryAmount,
    required double avgDaily,
    required double thisWeek,
    required double lastWeek,
    required int totalTransactions,
  }) {
    final tips = <Map<String, dynamic>>[];

    // Tip 1 — budget usage
    if (monthlyLimit > 0) {
      final percent = (totalSpent / monthlyLimit * 100).toInt();
      if (percent >= 80) {
        tips.add({
          'icon': Icons.warning_amber_rounded,
          'color': Colors.red,
          'title': 'Budget almost exhausted',
          'body':
              'You have used $percent% of your budget. Consider reducing spending for the rest of the month.',
        });
      } else if (percent >= 50) {
        tips.add({
          'icon': Icons.trending_up,
          'color': Colors.orange,
          'title': 'Halfway through budget',
          'body':
              'You have used $percent% of your monthly budget. Stay mindful of your remaining ৳ ${(monthlyLimit - totalSpent).toStringAsFixed(0)}.',
        });
      }
    }

    // Tip 2 — top category
    if (topCategory != 'None' && totalSpent > 0) {
      final percent = ((topCategoryAmount / totalSpent) * 100).toInt();
      if (percent >= 50) {
        tips.add({
          'icon': Icons.pie_chart,
          'color': AppColors.primary,
          'title': '$topCategory is your biggest expense',
          'body':
              '$percent% of your spending goes to $topCategory. See if you can reduce it next month.',
        });
      }
    }

    // Tip 3 — week comparison
    if (lastWeek > 0 && thisWeek > lastWeek) {
      final diff = ((thisWeek - lastWeek) / lastWeek * 100).toInt();
      tips.add({
        'icon': Icons.arrow_upward,
        'color': Colors.orange,
        'title': 'Spending increased this week',
        'body':
            'You are spending $diff% more than last week. Try to slow down before the week ends.',
      });
    }

    // Tip 4 — low transactions
    if (totalTransactions < 5) {
      tips.add({
        'icon': Icons.edit_note,
        'color': AppColors.primaryLight,
        'title': 'Log your expenses regularly',
        'body':
            'You only have $totalTransactions expenses recorded this month. Regular logging gives better insights.',
      });
    }

    // Tip 5 — high daily average
    if (avgDaily > 500) {
      tips.add({
        'icon': Icons.access_time,
        'color': Colors.red,
        'title': 'High daily spending',
        'body':
            'Your average is ৳ ${avgDaily.toStringAsFixed(0)} per day. Try to keep it under ৳ 500 for better savings.',
      });
    }

    // Tip 6 — doing well
    if (tips.isEmpty) {
      tips.add({
        'icon': Icons.thumb_up,
        'color': AppColors.primary,
        'title': 'You are doing great!',
        'body':
            'Your spending habits look healthy this month. Keep tracking to maintain this!',
      });
    }

    return tips;
  }

  // ── Tip card ──
  Widget _tipCard(Map<String, dynamic> tip) {
    final color = tip['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip['icon'] as IconData, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['body'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Insight card ──
  Widget _insightCard({
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Week stat ──
  Widget _weekStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Section title ──
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

  // ── Empty state ──
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 72, color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            'No insights yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some expenses to see your insights',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
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
}
