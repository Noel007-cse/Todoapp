// lib/presentation/screens/focus_timer_screen.dart — Dark Theme Focus Timer
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class FocusTimerScreen extends StatefulWidget {
  final Task task;
  const FocusTimerScreen({Key? key, required this.task}) : super(key: key);
  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  late int _totalSec, _remaining;
  bool _running = false, _done = false;
  Timer? _timer;
  int _selIdx = 2;
  late AnimationController _pulseCtrl;
  static const _durs = [
    {'label': '5 min', 'seconds': 300}, {'label': '15 min', 'seconds': 900},
    {'label': '25 min', 'seconds': 1500}, {'label': '45 min', 'seconds': 2700}, {'label': '60 min', 'seconds': 3600},
  ];

  @override
  void initState() {
    super.initState();
    _totalSec = _durs[_selIdx]['seconds'] as int;
    _remaining = _totalSec;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _start() { setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) { _timer?.cancel(); setState(() { _running = false; _done = true; });
        context.read<UserProvider>().addFocusMinutes(_totalSec ~/ 60);
        _showComplete();
      } else { setState(() => _remaining--); }
    });
  }
  void _pause() { _timer?.cancel(); setState(() => _running = false); }
  void _reset() { _timer?.cancel(); setState(() { _running = false; _done = false; _remaining = _totalSec; }); }
  void _selDur(int i) { if (_running) return; setState(() { _selIdx = i; _totalSec = _durs[i]['seconds'] as int; _remaining = _totalSec; _done = false; }); }

  String get _time { final m = (_remaining ~/ 60).toString().padLeft(2,'0'); final s = (_remaining % 60).toString().padLeft(2,'0'); return '$m:$s'; }
  double get _prog => _totalSec == 0 ? 0 : (_totalSec - _remaining) / _totalSec;

  void _showComplete() {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.primarySubtle, shape: BoxShape.circle),
          child: const Icon(Icons.check_circle, size: 44, color: AppColors.primary)),
        const SizedBox(height: 20),
        const Text('Focus Complete! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text('Great work on "${widget.task.title}"', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { Navigator.pop(ctx); _reset(); },
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('Again'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _markDone(); },
            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('Done ✓'))),
        ]),
      ]),
    ));
  }

  void _markDone() {
    final tp = context.read<TaskProvider>();
    final up = context.read<UserProvider>();
    tp.toggleTaskCompletion(widget.task.id);
    up.onTaskCompleted(priority: widget.task.priority, subtaskCount: widget.task.subtasks.length);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ "${widget.task.title}" completed!'),
      backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(backgroundColor: AppColors.bg, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textPrimary), onPressed: () {
          if (_running) {
            showDialog(context: context, builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Exit Focus Mode?', style: TextStyle(color: AppColors.textPrimary)),
              content: const Text('Timer is still running.', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
                TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  child: const Text('Leave', style: TextStyle(color: AppColors.danger))),
              ],
            ));
          } else Navigator.pop(context);
        }),
        title: const Text('Focus Mode', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        centerTitle: true),
      body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
        const SizedBox(height: 16),
        // Task info
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primarySubtle, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.task_alt, color: AppColors.primary, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.task.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(widget.task.category, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ])),
          ])),
        const SizedBox(height: 32),
        // Duration
        if (!_running) ...[
          const Text('SELECT DURATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_durs.length, (i) =>
            GestureDetector(onTap: () => _selDur(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: i == _selIdx ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: i == _selIdx ? AppColors.primary : AppColors.cardBorder)),
              child: Text(_durs[i]['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: i == _selIdx ? AppColors.bg : AppColors.textSecondary)))))),
          const SizedBox(height: 32),
        ] else const SizedBox(height: 32),
        // Timer circle
        ScaleTransition(scale: _running ? Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut))
          : const AlwaysStoppedAnimation(1.0),
          child: SizedBox(width: 260, height: 260, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 260, height: 260, child: CircularProgressIndicator(value: _prog, strokeWidth: 12, backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(_done ? AppColors.success : AppColors.primary))),
            Container(width: 220, height: 220, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_done) const Icon(Icons.check_circle, size: 56, color: AppColors.success)
                else ...[
                  Text(_time, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -2,
                    fontFeatures: [FontFeature.tabularFigures()])),
                  const SizedBox(height: 6),
                  Text(_running ? 'FOCUSING' : 'READY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                    color: _running ? AppColors.primary : AppColors.textMuted)),
                ],
              ])),
          ]))),
        const SizedBox(height: 40),
        if (!_done) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(onTap: _reset, child: Container(width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder)),
            child: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 24))),
          const SizedBox(width: 20),
          GestureDetector(onTap: _running ? _pause : _start, child: Container(width: 80, height: 80,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Icon(_running ? Icons.pause : Icons.play_arrow, color: AppColors.bg, size: 36))),
          const SizedBox(width: 20),
          GestureDetector(onTap: _markDone, child: Container(width: 56, height: 56,
            decoration: BoxDecoration(color: AppColors.primarySubtle, shape: BoxShape.circle, border: Border.all(color: AppColors.primary.withOpacity(0.3))),
            child: const Icon(Icons.check, color: AppColors.primary, size: 24))),
        ]),
        const SizedBox(height: 100),
      ]))),
    );
  }
}