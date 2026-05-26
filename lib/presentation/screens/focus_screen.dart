// lib/presentation/screens/focus_screen.dart — Focus Tab with Pomodoro
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({Key? key}) : super(key: key);
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  int _totalSec = 1500; int _remaining = 1500; bool _running = false; bool _done = false;
  Timer? _timer; int _selIdx = 2;
  String _sound = 'None';
  late AnimationController _pulseCtrl;
  static const _durs = [
    {'label': '5m', 'sec': 300}, {'label': '15m', 'sec': 900},
    {'label': '25m', 'sec': 1500}, {'label': '45m', 'sec': 2700}, {'label': '60m', 'sec': 3600},
  ];
  static const _sounds = ['None', '🌧️ Rain', '☕ Cafe', '🔊 Brown Noise', '🎵 Lo-fi'];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); super.dispose(); }

  void _start() { setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) { _timer?.cancel(); setState(() { _running = false; _done = true; });
        context.read<UserProvider>().addFocusMinutes(_totalSec ~/ 60);
      } else { setState(() => _remaining--); }
    });
  }
  void _pause() { _timer?.cancel(); setState(() => _running = false); }
  void _reset() { _timer?.cancel(); setState(() { _running = false; _done = false; _remaining = _totalSec; }); }
  void _selDur(int i) { if (_running) return; setState(() { _selIdx = i; _totalSec = _durs[i]['sec'] as int; _remaining = _totalSec; _done = false; }); }

  String get _time { final m = (_remaining ~/ 60).toString().padLeft(2,'0'); final s = (_remaining % 60).toString().padLeft(2,'0'); return '$m:$s'; }
  double get _prog => _totalSec == 0 ? 0 : (_totalSec - _remaining) / _totalSec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.bg, body: SafeArea(child: SingleChildScrollView(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const SizedBox(height: 12),
        // App Bar
        Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.self_improvement, color: AppColors.bg, size: 18)),
          const SizedBox(width: 10),
          const Text('Focus Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 32),
        // Duration selector
        if (!_running) ...[
          const Text('SELECT DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_durs.length, (i) =>
            GestureDetector(onTap: () => _selDur(i), child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: i == _selIdx ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20),
                border: Border.all(color: i == _selIdx ? AppColors.primary : AppColors.cardBorder)),
              child: Text(_durs[i]['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: i == _selIdx ? AppColors.bg : AppColors.textSecondary)),
            )),
          )),
          const SizedBox(height: 16),
          // Sound selector
          const Text('AMBIENT SOUND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _sounds.map((s) =>
            GestureDetector(onTap: () => setState(() => _sound = s),
              child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _sound == s ? AppColors.accent.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: _sound == s ? AppColors.accent : AppColors.cardBorder)),
                child: Text(s, style: TextStyle(fontSize: 12, color: _sound == s ? AppColors.accent : AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ),
          ).toList())),
          const SizedBox(height: 32),
        ] else const SizedBox(height: 32),
        // Timer Circle
        ScaleTransition(scale: _running
          ? Tween<double>(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut))
          : const AlwaysStoppedAnimation(1.0),
          child: SizedBox(width: 260, height: 260, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 260, height: 260, child: CircularProgressIndicator(
              value: _prog, strokeWidth: 10, backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(_done ? AppColors.success : AppColors.primary))),
            Container(width: 220, height: 220, decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle,
              boxShadow: [if (_running) BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 40)]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_done) const Icon(Icons.check_circle, size: 56, color: AppColors.success)
                else ...[
                  Text(_time, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -2,
                    fontFeatures: [FontFeature.tabularFigures()])),
                  const SizedBox(height: 6),
                  Text(_running ? 'FOCUSING' : 'READY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
                    color: _running ? AppColors.primary : AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('${(_prog * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                ],
              ])),
          ])),
        ),
        const SizedBox(height: 40),
        // Controls
        if (!_done) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _CircleBtn(icon: Icons.refresh, color: AppColors.surfaceLight, iconColor: AppColors.textSecondary, onTap: _reset),
          const SizedBox(width: 20),
          GestureDetector(onTap: _running ? _pause : _start, child: Container(width: 80, height: 80,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Icon(_running ? Icons.pause : Icons.play_arrow, color: AppColors.bg, size: 36))),
          const SizedBox(width: 20),
          _CircleBtn(icon: Icons.check, color: AppColors.surface, iconColor: AppColors.primary, onTap: () {
            context.read<UserProvider>().addFocusMinutes((_totalSec - _remaining) ~/ 60);
            Navigator.of(context).maybePop();
          }),
        ]),
        if (_done) ...[
          const SizedBox(height: 16),
          const Text('Session Complete! 🎉', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Great focus session. You earned ${_totalSec ~/ 60 * 2} XP!', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            OutlinedButton(onPressed: _reset, style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
              child: const Text('Again')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Done ✓')),
          ]),
        ],
        // Stats
        const SizedBox(height: 40),
        Consumer<UserProvider>(builder: (_, up, __) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            Expanded(child: Column(children: [
              Text('${up.profile.totalFocusMinutes}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Text('Total Minutes', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(width: 1, height: 40, color: AppColors.cardBorder),
            Expanded(child: Column(children: [
              Text('${up.profile.totalFocusMinutes ~/ 60}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.accent)),
              const Text('Total Hours', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
            Container(width: 1, height: 40, color: AppColors.cardBorder),
            Expanded(child: Column(children: [
              Text('${up.profile.level}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.xpGold)),
              const Text('Level', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ])),
          ]),
        )),
        const SizedBox(height: 100),
      ]),
    ))));
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon; final Color color, iconColor; final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.iconColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Container(width: 56, height: 56,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AppColors.cardBorder)),
      child: Icon(icon, color: iconColor, size: 24)));
  }
}
