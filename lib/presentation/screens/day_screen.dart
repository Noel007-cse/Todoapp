// lib/presentation/screens/day_screen.dart — Main Day Tab
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../providers/habit_provider.dart';
import 'add_edit_task_screen.dart';
import 'focus_timer_screen.dart';

class DayScreen extends StatefulWidget {
  const DayScreen({Key? key}) : super(key: key);
  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Consumer3<TaskProvider, UserProvider, HabitProvider>(
      builder: (context, tp, up, hp, _) {
        final now = DateTime.now();
        final profile = up.profile;
        final pending = tp.pendingTasks;
        final today = DateTime(now.year, now.month, now.day);
        final todayTasks = tp.allTasks.where((t) {
          final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return d == today;
        }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final topTasks = pending.take(3).toList();
        final mission = pending.isNotEmpty ? pending.first : null;
        final greeting = now.hour < 12 ? 'Good Morning,' : now.hour < 17 ? 'Good Afternoon,' : 'Good Evening,';
        final energy = todayTasks.fold<int>(0, (s, t) => s + t.energyCost);
        final ctx = energy <= 8 ? "Your cognitive load is low. It's a perfect day for high-impact strategy."
            : energy <= 15 ? "A balanced day ahead. Focus on your top priorities first."
            : "Heavy day ahead. Consider rescheduling non-essential tasks.";

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(child: CustomScrollView(slivers: [
            // App Bar
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.self_improvement, color: AppColors.bg, size: 18)),
                const SizedBox(width: 10),
                const Text('Mindful Flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const Spacer(),
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
              ]),
            )),
            // Greeting
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(greeting, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
                Text(profile.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary, height: 1.2)),
                const SizedBox(height: 8),
                Text(ctx, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              ]),
            )),
            // Priority Focus
            if (topTasks.isNotEmpty) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Text('PRIORITY FOCUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8))),
                  const SizedBox(height: 14),
                  ...topTasks.map((t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(
                    onTap: () => tp.toggleTaskCompletion(t.id),
                    child: Row(children: [
                      Container(width: 18, height: 18, decoration: BoxDecoration(
                        color: t.isCompleted ? AppColors.primary : Colors.transparent, shape: BoxShape.circle,
                        border: Border.all(color: t.isCompleted ? AppColors.primary : AppColors.textMuted, width: 2)),
                        child: t.isCompleted ? const Icon(Icons.check, size: 10, color: AppColors.bg) : null),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: t.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                        decoration: t.isCompleted ? TextDecoration.lineThrough : null))),
                    ]),
                  ))),
                ]),
              ),
            )),
            // Quote
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('"The secret of getting ahead is getting started. Your momentum from yesterday is your fuel today."',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.primary.withOpacity(0.8), height: 1.5)),
            )),
            // Current Mission
            if (mission != null) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _MissionCard(task: mission, onFocus: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FocusTimerScreen(task: mission)))),
            )),
            // Energy AI Card
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _EnergyCard(topTask: pending.length > 1 ? pending[1] : null),
            )),
            // Timeline header
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(children: [
                const Icon(Icons.schedule, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            )),
            // Timeline items
            todayTasks.isEmpty
              ? SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No tasks for today', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ]))))
              : SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                  final t = todayTasks[i];
                  return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 10), child: Row(children: [
                    SizedBox(width: 48, child: Text(DateFormat('HH:mm').format(t.dueDate),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.isCompleted ? AppColors.textMuted : AppColors.textSecondary))),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(fullscreenDialog: true, builder: (_) => AddEditTaskScreen(task: t))),
                      child: Container(padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                        child: Row(children: [
                          GestureDetector(onTap: () => tp.toggleTaskCompletion(t.id),
                            child: Container(width: 20, height: 20, decoration: BoxDecoration(
                              color: t.isCompleted ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: t.isCompleted ? AppColors.primary : AppColors.textMuted, width: 2)),
                              child: t.isCompleted ? const Icon(Icons.check, size: 12, color: AppColors.bg) : null)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(t.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: t.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                              decoration: t.isCompleted ? TextDecoration.lineThrough : null)),
                            if (t.description?.isNotEmpty == true)
                              Text(t.description!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
                        ]),
                      ),
                    )),
                  ]));
                }, childCount: todayTasks.length)),
            // Live Habits
            if (hp.habits.isNotEmpty) SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: const Text('LIVE HABITS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted)),
            )),
            if (hp.habits.isNotEmpty) SliverToBoxAdapter(child: SizedBox(height: 80, child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hp.habits.length, itemBuilder: (_, i) {
                final h = hp.habits[i]; final done = h.isCompletedToday;
                return GestureDetector(onTap: () => hp.toggleHabitForToday(h.id), child: Container(width: 72, margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(
                      color: done ? AppColors.primary.withOpacity(0.2) : AppColors.surface, shape: BoxShape.circle,
                      border: Border.all(color: done ? AppColors.primary : AppColors.cardBorder, width: 2)),
                      child: Center(child: Text(h.icon, style: const TextStyle(fontSize: 20)))),
                    const SizedBox(height: 6),
                    Text(h.name, style: TextStyle(fontSize: 10, color: done ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])));
              },
            ))),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ])),
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Task task; final VoidCallback onFocus;
  const _MissionCard({required this.task, required this.onFocus});
  @override
  Widget build(BuildContext context) {
    final r = task.timeRemaining;
    final h = r.inHours.abs(); final m = (r.inMinutes % 60).abs(); final s = (r.inSeconds % 60).abs();
    return Container(padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Text('CURRENT MISSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.8))),
        const SizedBox(height: 16),
        Text(task.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.2)),
        const SizedBox(height: 8),
        Text('Deep work session · ${task.estimatedMinutes} minutes · focused on ${task.category}',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        Center(child: Text('${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -2, fontFeatures: [FontFeature.tabularFigures()]))),
        const SizedBox(height: 20),
        Center(child: GestureDetector(onTap: onFocus, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
          child: const Text('Focus Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.bg))))),
      ]),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  final Task? topTask;
  const _EnergyCard({this.topTask});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
          child: const Text('SENTIENT AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.accent, letterSpacing: 0.5)))]),
        const SizedBox(height: 8),
        const Row(children: [Icon(Icons.bolt, color: AppColors.energy, size: 22), SizedBox(width: 8),
          Text('Energy peak detected.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary))]),
        const SizedBox(height: 8),
        RichText(text: TextSpan(style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5), children: [
          const TextSpan(text: "You're usually sharpest now. Should we tackle the "),
          TextSpan(text: topTask?.title ?? 'next task', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const TextSpan(text: '?'),
        ])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(height: 42, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(21)),
            child: const Center(child: Text("Let's do it", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.bg))))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 42, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(21), border: Border.all(color: AppColors.cardBorder)),
            child: const Center(child: Text('Later', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))))),
        ]),
      ]),
    );
  }
}
