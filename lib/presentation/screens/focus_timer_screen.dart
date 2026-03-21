// lib/presentation/screens/focus_timer_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';

class FocusTimerScreen extends StatefulWidget {
  final Task task;

  const FocusTimerScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen>
    with TickerProviderStateMixin {
  // ─── Timer state ───────────────────────────────────────────────────────────
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isRunning = false;
  bool _isFinished = false;
  Timer? _timer;

  // ─── Selected duration options ─────────────────────────────────────────────
  static const List<Map<String, dynamic>> _durations = [
    {'label': '5 min', 'seconds': 300},
    {'label': '15 min', 'seconds': 900},
    {'label': '25 min', 'seconds': 1500},
    {'label': '45 min', 'seconds': 2700},
    {'label': '60 min', 'seconds': 3600},
  ];
  int _selectedDurationIndex = 2; // Default 25 min

  // ─── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _totalSeconds = _durations[_selectedDurationIndex]['seconds'] as int;
    _remainingSeconds = _totalSeconds;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Timer Logic ───────────────────────────────────────────────────────────
  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isFinished = false;
      _remainingSeconds = _totalSeconds;
    });
  }

  void _selectDuration(int index) {
    if (_isRunning) return;
    setState(() {
      _selectedDurationIndex = index;
      _totalSeconds = _durations[index]['seconds'] as int;
      _remainingSeconds = _totalSeconds;
      _isFinished = false;
    });
  }

  void _onTimerComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.bgLight,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.cardBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  size: 44, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Focus Complete! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great work on "${widget.task.title}"',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _resetTimer();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _markComplete();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Done ✓'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markComplete() {
    context.read<TaskProvider>().toggleTaskCompletion(widget.task.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${widget.task.title}" completed!'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  String get _timeDisplay {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress =>
      _totalSeconds == 0 ? 0 : (_totalSeconds - _remainingSeconds) / _totalSeconds;

  String get _progressText {
    final pct = (_progress * 100).round();
    return '$pct%';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primaryColor),
          onPressed: () {
            if (_isRunning) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('Exit Focus Mode?'),
                  content: const Text(
                      'Timer is still running. Are you sure you want to leave?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Stay'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Leave',
                          style: TextStyle(color: AppTheme.danger)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Focus Mode',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ── Task info ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.task_alt,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.task.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.task.category.isNotEmpty
                                ? widget.task.category[0].toUpperCase() +
                                    widget.task.category.substring(1)
                                : 'Task',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Duration selector ──────────────────────────────────────
              if (!_isRunning) ...[
                Text(
                  'SELECT DURATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_durations.length, (i) {
                    final isSelected = i == _selectedDurationIndex;
                    return GestureDetector(
                      onTap: () => _selectDuration(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _durations[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
              ] else
                const SizedBox(height: 32),

              // ── Timer circle ───────────────────────────────────────────
              ScaleTransition(
                scale: _isRunning ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 12,
                          backgroundColor: AppTheme.cardBlue,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isFinished
                                ? const Color(0xFF00897B)
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),

                      // Inner circle
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isFinished)
                              const Icon(Icons.check_circle,
                                  size: 56, color: Color(0xFF00897B))
                            else ...[
                              Text(
                                _timeDisplay,
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDark,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isRunning ? 'FOCUSING' : 'READY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: AppTheme.primaryColor.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _progressText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Control buttons ────────────────────────────────────────
              if (!_isFinished) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset button
                    GestureDetector(
                      onTap: _resetTimer,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.refresh,
                          color: AppTheme.primaryColor.withOpacity(0.6),
                          size: 24,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Play / Pause
                    GestureDetector(
                      onTap: _isRunning ? _pauseTimer : _startTimer,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Mark complete button
                    GestureDetector(
                      onTap: _markComplete,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        'Reset',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const SizedBox(width: 80),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 56,
                      child: Text(
                        'Done',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // ── Subtasks progress ──────────────────────────────────────
              if (widget.task.subtasks.isNotEmpty) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Breakdown',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          Text(
                            '${widget.task.subtasks.where((s) => s.isCompleted).length}/${widget.task.subtasks.length}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...widget.task.subtasks.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  s.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: s.isCompleted
                                      ? AppTheme.primaryColor
                                      : AppTheme.primaryColor.withOpacity(0.3),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: s.isCompleted
                                          ? AppTheme.primaryColor
                                              .withOpacity(0.4)
                                          : AppTheme.primaryDark,
                                      decoration: s.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}