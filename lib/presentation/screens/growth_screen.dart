// lib/presentation/screens/growth_screen.dart — Growth Tab (Screenshot 2)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../providers/analytics_provider.dart';

class GrowthScreen extends StatelessWidget {
  const GrowthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<TaskProvider, UserProvider, AnalyticsProvider>(
      builder: (context, tp, up, ap, _) {
        final profile = up.profile;
        final completed = tp.completedTasks.length;
        final total = tp.allTasks.length;
        final rate = total == 0 ? 0 : ((completed / total) * 100).round();
        final stats = ap.getTotalStats();
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(child: CustomScrollView(slivers: [
            // App Bar
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(children: [
                Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.self_improvement, color: AppColors.bg, size: 18)),
                const SizedBox(width: 10),
                const Text('Mindful Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Spacer(),
                const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 22),
              ]),
            )),
            // Weekly Review Card
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.surface, AppColors.surfaceLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    const Text('SENTIENT WEEKLY REVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
                    const Spacer(),
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), shape: BoxShape.circle),
                      child: const Icon(Icons.person, color: AppColors.primary, size: 18)),
                  ]),
                  const SizedBox(height: 16),
                  RichText(text: TextSpan(children: [
                    const TextSpan(text: "You're in the ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const TextSpan(text: 'Top 2%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const TextSpan(text: ' of\nCognitive Clarity.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  ])),
                  const SizedBox(height: 12),
                  Text('This week, your "Flow State" peaked on Tuesday during deep-work blocks. AI analysis suggests your productivity is 14% higher when starting tasks before 9 AM.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                ]),
              ),
            )),
            // Heatmap
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Productivity Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('Last  ', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.heatmap1, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 2),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.heatmap3, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 2),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.heatmap5, borderRadius: BorderRadius.circular(2))),
                    const Text('  More', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 12),
                  _HeatmapGrid(taskProvider: tp),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
                    Text('Jan', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Feb', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Mar', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Apr', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('May', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Jun', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Jul', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Aug', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Sep', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Oct', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Nov', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    Text('Dec', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ]),
                ]),
              ),
            )),
            // Level Card
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.surface]),
                  borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('LVL ${profile.level}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.bg))),
                    const SizedBox(width: 10),
                    Text(profile.levelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const Spacer(),
                    const Icon(Icons.emoji_events, color: AppColors.xpGold, size: 24),
                  ]),
                  const SizedBox(height: 16),
                  // XP bar
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: profile.xpProgress, minHeight: 8, backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary))),
                  const SizedBox(height: 6),
                  Text('${profile.xp} / ${profile.xpForNextLevel} XP', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _StatBox(label: 'Mastery', value: '${profile.totalTasksCompleted}', sub: 'Tasks Completed')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBox(label: 'Focus Score', value: '$rate%', sub: 'Weekly Average')),
                  ]),
                ]),
              ),
            )),
            // Peak Hours Chart
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Text('Peak Velocity Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Spacer(),
                    Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(height: 150, child: _PeakHoursChart(taskProvider: tp)),
                ]),
              ),
            )),
            // Balance Ratio
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Balance Ratio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  Row(children: [
                    SizedBox(width: 100, height: 100, child: _BalanceChart(taskProvider: tp)),
                    const SizedBox(width: 20),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _LegendItem(color: AppColors.primary, label: 'Work & Depth', pct: '78%'),
                      const SizedBox(height: 8),
                      _LegendItem(color: AppColors.accent, label: 'Life & Leisure', pct: '22%'),
                    ])),
                  ]),
                ]),
              ),
            )),
            // Achievements
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(children: [
                const Text('Active Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                Text('VIEW ALL ›', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            )),
            SliverToBoxAdapter(child: SizedBox(height: 100, child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _AchievementCard(icon: '🌅', name: 'EARLY BIRD', desc: 'Complete before 7am', unlocked: up.hasAchievement('early_bird')),
                _AchievementCard(icon: '⚡', name: 'DEEP WORKER', desc: '90-min focus session', unlocked: up.hasAchievement('deep_worker')),
                _AchievementCard(icon: '🔥', name: 'ON FIRE', desc: '5-day streak', unlocked: up.hasAchievement('five_streak')),
                _AchievementCard(icon: '💯', name: 'CENTURION', desc: '100 total tasks', unlocked: up.hasAchievement('century')),
                _AchievementCard(icon: '🧘', name: 'FOCUS MASTER', desc: '500 focus minutes', unlocked: up.hasAchievement('focus_master')),
              ],
            ))),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ])),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value, sub;
  const _StatBox({required this.label, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final TaskProvider taskProvider;
  const _HeatmapGrid({required this.taskProvider});
  @override
  Widget build(BuildContext context) {
    final rand = Random(42);
    return SizedBox(height: 7 * 10.0 + 6 * 2,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(52, (week) => Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (day) {
            final intensity = rand.nextInt(6);
            final colors = [AppColors.heatmap0, AppColors.heatmap1, AppColors.heatmap2, AppColors.heatmap3, AppColors.heatmap4, AppColors.heatmap5];
            return Container(width: 5, height: 5, decoration: BoxDecoration(color: colors[intensity], borderRadius: BorderRadius.circular(1)));
          }),
        )),
      ),
    );
  }
}

class _PeakHoursChart extends StatelessWidget {
  final TaskProvider taskProvider;
  const _PeakHoursChart({required this.taskProvider});
  @override
  Widget build(BuildContext context) {
    final data = List.generate(24, (h) {
      final count = taskProvider.completedTasks.where((t) => t.completedDate?.hour == h).length;
      return count.toDouble();
    });
    final maxVal = data.reduce((a, b) => a > b ? a : b).clamp(1, 999);
    final peakHour = data.indexOf(data.reduce((a, b) => a > b ? a : b));
    return BarChart(BarChartData(
      barGroups: List.generate(12, (i) {
        final h = i * 2;
        final val = data[h] + data[h + 1];
        return BarChartGroupData(x: h, barRods: [BarChartRodData(
          toY: val == 0 ? 0.3 : val, width: 12, borderRadius: BorderRadius.circular(4),
          color: (h == peakHour || h + 1 == peakHour) ? AppColors.primary : AppColors.primary.withOpacity(0.3),
        )]);
      }),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 20,
          getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.textMuted)))),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    ));
  }
}

class _BalanceChart extends StatelessWidget {
  final TaskProvider taskProvider;
  const _BalanceChart({required this.taskProvider});
  @override
  Widget build(BuildContext context) {
    final workTasks = taskProvider.completedTasks.where((t) => t.category == 'work').length;
    final total = taskProvider.completedTasks.length.clamp(1, 99999);
    final workPct = (workTasks / total * 100).clamp(10.0, 90.0);
    return PieChart(PieChartData(
      sectionsSpace: 2, centerSpaceRadius: 30,
      sections: [
        PieChartSectionData(value: workPct.toDouble(), color: AppColors.primary, radius: 16, showTitle: false),
        PieChartSectionData(value: (100.0 - workPct).toDouble(), color: AppColors.accent, radius: 14, showTitle: false),
      ],
    ));
  }
}

class _LegendItem extends StatelessWidget {
  final Color color; final String label, pct;
  const _LegendItem({required this.color, required this.label, required this.pct});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      const Spacer(),
      Text(pct, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _AchievementCard extends StatelessWidget {
  final String icon, name, desc;
  final bool unlocked;
  const _AchievementCard({required this.icon, required this.name, required this.desc, required this.unlocked});
  @override
  Widget build(BuildContext context) {
    return Container(width: 120, margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? AppColors.primary.withOpacity(0.4) : AppColors.cardBorder)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: TextStyle(fontSize: 24, color: unlocked ? null : AppColors.textMuted)),
        const SizedBox(height: 6),
        Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: unlocked ? AppColors.primary : AppColors.textMuted, letterSpacing: 0.5)),
        Text(desc, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), textAlign: TextAlign.center),
      ]),
    );
  }
}
