// lib/presentation/screens/flow_screen.dart — Habits, Wellbeing, Journal
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_models.dart';
import '../providers/habit_provider.dart';
import '../providers/user_provider.dart';

class FlowScreen extends StatefulWidget {
  const FlowScreen({Key? key}) : super(key: key);
  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  int _breathPhase = 0; // 0=idle, 1=inhale, 2=hold, 3=exhale
  Timer? _breathTimer;
  double _breathScale = 1.0;
  final _journalCtrl = TextEditingController();

  @override
  void dispose() { _breathTimer?.cancel(); _journalCtrl.dispose(); super.dispose(); }

  void _startBreathing() {
    setState(() { _breathPhase = 1; _breathScale = 1.0; });
    _runBreathCycle();
  }

  void _runBreathCycle() {
    // Inhale 4s
    setState(() { _breathPhase = 1; _breathScale = 1.5; });
    _breathTimer = Timer(const Duration(seconds: 4), () {
      // Hold 7s
      setState(() => _breathPhase = 2);
      _breathTimer = Timer(const Duration(seconds: 7), () {
        // Exhale 8s
        setState(() { _breathPhase = 3; _breathScale = 1.0; });
        _breathTimer = Timer(const Duration(seconds: 8), () {
          if (mounted) _runBreathCycle();
        });
      });
    });
  }

  void _stopBreathing() {
    _breathTimer?.cancel();
    setState(() { _breathPhase = 0; _breathScale = 1.0; });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HabitProvider, UserProvider>(builder: (context, hp, up, _) {
      final habits = hp.habits;
      final mood = up.todaysMood;
      return Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: CustomScrollView(slivers: [
        // App Bar
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 16, 0), child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.self_improvement, color: AppColors.bg, size: 18)),
          const SizedBox(width: 10),
          const Text('Flow & Wellbeing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]))),

        // Mood Check-in
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('How are you feeling?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Spacer(),
              if (mood != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: const Text('✓ Logged', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary))),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _MoodEmoji(emoji: '😫', label: 'Rough', value: 1, selected: mood?.mood == 1, onTap: () => up.logMood(1)),
              _MoodEmoji(emoji: '😕', label: 'Low', value: 2, selected: mood?.mood == 2, onTap: () => up.logMood(2)),
              _MoodEmoji(emoji: '😐', label: 'Okay', value: 3, selected: mood?.mood == 3, onTap: () => up.logMood(3)),
              _MoodEmoji(emoji: '😊', label: 'Good', value: 4, selected: mood?.mood == 4, onTap: () => up.logMood(4)),
              _MoodEmoji(emoji: '🤩', label: 'Great', value: 5, selected: mood?.mood == 5, onTap: () => up.logMood(5)),
            ]),
          ]),
        ))),

        // Habits
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Row(children: [
          const Text('Daily Habits', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Text('${hp.completedToday}/${hp.totalActiveHabits}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ]))),

        if (habits.isEmpty)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), child: _AddHabitCard(onAdd: (tmpl) => hp.addFromTemplate(tmpl))))
        else
          SliverList(delegate: SliverChildBuilderDelegate((_, i) {
            final h = habits[i];
            return Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: GestureDetector(
              onTap: () => hp.toggleHabitForToday(h.id),
              child: Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: h.isCompletedToday ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: h.isCompletedToday ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder)),
                child: Row(children: [
                  Text(h.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(h.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: h.isCompletedToday ? AppColors.primary : AppColors.textPrimary)),
                    Text('${h.currentStreak} day streak', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ])),
                  if (h.currentStreak > 0) Text('🔥${h.currentStreak}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(width: 24, height: 24, decoration: BoxDecoration(
                    color: h.isCompletedToday ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(6), border: Border.all(color: h.isCompletedToday ? AppColors.primary : AppColors.textMuted, width: 2)),
                    child: h.isCompletedToday ? const Icon(Icons.check, size: 14, color: AppColors.bg) : null),
                ]),
              ),
            ));
          }, childCount: habits.length)),

        // Add Habit Button
        if (habits.isNotEmpty)
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 0), child: GestureDetector(
            onTap: () => _showAddHabitSheet(context, hp),
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
              color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add, size: 18, color: AppColors.textMuted),
                SizedBox(width: 8),
                Text('Add Habit', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ]),
            ),
          ))),

        // Breathing Exercise
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Column(children: [
            const Text('Breathing Exercise', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('4-7-8 technique', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            AnimatedContainer(duration: const Duration(seconds: 4), curve: Curves.easeInOut,
              width: 100 * _breathScale, height: 100 * _breathScale,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.3), AppColors.primary.withOpacity(0.05)])),
              child: Center(child: Text(
                _breathPhase == 0 ? '🧘' : _breathPhase == 1 ? 'Inhale' : _breathPhase == 2 ? 'Hold' : 'Exhale',
                style: TextStyle(fontSize: _breathPhase == 0 ? 32 : 16, fontWeight: FontWeight.w700, color: AppColors.primary),
              )),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _breathPhase == 0 ? _startBreathing : _stopBreathing,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: _breathPhase == 0 ? AppColors.primary : AppColors.danger, borderRadius: BorderRadius.circular(24)),
                child: Text(_breathPhase == 0 ? 'Start' : 'Stop', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.bg)),
              ),
            ),
          ]),
        ))),

        // Gratitude / Journal
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gratitude & Journal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('What went well today?', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextField(controller: _journalCtrl, maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(hintText: 'Write something you\'re grateful for...', hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.surfaceLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            GestureDetector(onTap: () {
              if (_journalCtrl.text.trim().isNotEmpty) {
                up.addJournalEntry(_journalCtrl.text.trim());
                _journalCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('✨ Journal saved'),
                  backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              }
            }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: const Text('Save Entry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.bg)),
            )),
          ]),
        ))),

        // Wellbeing Score
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text('${up.profile.currentStreak}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.streak)),
              const Text('Day Streak', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(width: 1, height: 40, color: AppColors.cardBorder),
            Expanded(child: Column(children: [
              Text('${up.profile.bestStreak}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.xpGold)),
              const Text('Best Streak', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(width: 1, height: 40, color: AppColors.cardBorder),
            Expanded(child: Column(children: [
              Text('${hp.longestStreak}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Text('Habit Best', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
          ]),
        ))),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ])));
    });
  }

  void _showAddHabitSheet(BuildContext context, HabitProvider hp) {
    showModalBottomSheet(context: context, backgroundColor: AppColors.surface, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.6, maxChildSize: 0.9, minChildSize: 0.3,
        expand: false, builder: (_, scroll) => ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Add a Habit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Choose from templates or create your own', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ...HabitProvider.templates.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
            onTap: () { hp.addFromTemplate(t); Navigator.pop(context); },
            child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                Text(t['icon']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(t['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const Spacer(),
                const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              ]),
            ),
          ))),
        ]),
      ),
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  final String emoji, label; final int value; final bool selected; final VoidCallback onTap;
  const _MoodEmoji({required this.emoji, required this.label, required this.value, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8), decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12), border: selected ? Border.all(color: AppColors.primary) : null),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textMuted, fontWeight: FontWeight.w600)),
      ]),
    ));
  }
}

class _AddHabitCard extends StatelessWidget {
  final Function(Map<String, String>) onAdd;
  const _AddHabitCard({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final templates = HabitProvider.templates.take(6).toList();
    return Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Start Your First Habit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Tap to add from popular templates', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: templates.map((t) => GestureDetector(onTap: () => onAdd(t),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(t['icon']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(t['name']!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ]),
          ),
        )).toList()),
      ]),
    );
  }
}
