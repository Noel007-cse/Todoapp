// lib/presentation/widgets/analytics_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsCard extends StatelessWidget {
  final int completed;
  final int total;
  final double completionPercentage;
  final List<int> last7DaysData;

  const AnalyticsCard({
    Key? key,
    required this.completed,
    required this.total,
    required this.completionPercentage,
    required this.last7DaysData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Today's Stats
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Productivity",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    /// Stats Grid
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _StatItem(
                          label: 'Completed',
                          value: completed.toString(),
                          color: AppTheme.successColor,
                        ),
                        _StatItem(
                          label: 'Pending',
                          value: (total - completed).toString(),
                          color: AppTheme.warningColor,
                        ),
                        _StatItem(
                          label: 'Total',
                          value: total.toString(),
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// Completion Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completion Rate',
                              style:
                                  Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              '${completionPercentage.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : completed / total,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.primaryColor.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completionPercentage >= 75
                                  ? AppTheme.successColor
                                  : completionPercentage >= 50
                                      ? AppTheme.accentColor
                                      : AppTheme.dangerColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Last 7 Days Chart
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last 7 Days',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (last7DaysData.isEmpty
                                  ? 10
                                  : last7DaysData.reduce(
                                      (a, b) => a > b ? a : b))
                              .toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: AppTheme.primaryColor,
                              tooltipRoundedRadius: 8,
                              tooltipMargin: 8,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  );
                                },
                                reservedSize: 28,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final days = ['Mon', 'Tue', 'Wed',
                                      'Thu', 'Fri', 'Sat', 'Sun'];
                                  return Text(
                                    days[value.toInt() % 7],
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  );
                                },
                                reservedSize: 28,
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles:
                                  SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            last7DaysData.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: last7DaysData[index].toDouble(),
                                  color: AppTheme.primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
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
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                color: color,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}