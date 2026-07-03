import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../providers/month_provider.dart';
import '../widgets/month_navigator.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(monthProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final categoryTotals = notifier.categoryTotalsForMonth(selectedMonth);
    final thisMonthTotal = notifier.totalForMonth(selectedMonth);
    final weeklyTotals = notifier.weeklyTotalsForMonth(selectedMonth);
    final monthExpenses = notifier.expensesForMonth(selectedMonth);
    final isEmpty = categoryTotals.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: const MonthNavigator(),
          ),
        ),
      ),
      body: isEmpty
          ? _buildEmpty()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Pie chart card ──
                  _sectionTitle('Spending by Category'),
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
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 52,
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event
                                                .isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection ==
                                                null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                      });
                                    },
                              ),
                              sections: _buildPieSections(
                                categoryTotals,
                                thisMonthTotal,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── Legend ──
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: categoryTotals.entries.map((entry) {
                            final color = _categoryColor(entry.key);
                            final percent = thisMonthTotal == 0
                                ? 0.0
                                : (entry.value / thisMonthTotal * 100);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${entry.key} ${percent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Bar chart ──
                  _sectionTitle('Weekly Spending'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (weeklyTotals.values.isEmpty
                                      ? 100
                                      : weeklyTotals.values.reduce(
                                              (a, b) => a > b ? a : b,
                                            ) *
                                            1.3)
                                  .toDouble(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '৳ ${rod.toY.toStringAsFixed(0)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const weeks = ['W1', 'W2', 'W3', 'W4'];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      weeks[value.toInt()],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '৳${value.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: weeklyTotals.entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key - 1,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value,
                                  color: AppColors.primary,
                                  width: 28,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Top spending ──
                  _sectionTitle('Top Expenses This Month'),
                  const SizedBox(height: 12),
                  ...monthExpenses
                      .where((e) {
                        final now = DateTime.now();
                        return e.date.month == now.month &&
                            e.date.year == now.year;
                      })
                      .toList()
                      .sorted()
                      .take(5)
                      .map((expense) {
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Text(
                                '৳ ${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                ],
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 72, color: AppColors.accent),
          SizedBox(height: 16),
          Text(
            'No data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add some expenses to see your analytics',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── Pie sections ──
  List<PieChartSectionData> _buildPieSections(
    Map<String, double> totals,
    double total,
  ) {
    final entries = totals.entries.toList();
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final entry = entries[i];
      final percent = total == 0 ? 0.0 : (entry.value / total * 100);
      return PieChartSectionData(
        color: _categoryColor(entry.key),
        value: entry.value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: isTouched ? 72 : 60,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
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

// ── Extension to sort expenses by amount ──
extension SortedExpenses on List {
  List sorted() {
    final copy = [...this];
    copy.sort((a, b) => b.amount.compareTo(a.amount));
    return copy;
  }
}
