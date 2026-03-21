// lib/presentation/screens/weekly_focus_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';
import 'add_edit_task_screen.dart';

class WeeklyFocusScreen extends StatefulWidget {
  const WeeklyFocusScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyFocusScreen> createState() => _WeeklyFocusScreenState();
}

class _WeeklyFocusScreenState extends State<WeeklyFocusScreen> {
  late DateTime _weekStart;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Week starts on Monday
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
    _selectedDayIndex = now.weekday - 1; // 0=Mon … 6=Sun
  }

  DateTime get _selectedDate =>
      _weekStart.add(Duration(days: _selectedDayIndex));

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final sel = _selectedDate;
        final selDay = DateTime(sel.year, sel.month, sel.day);

        final dayTasks = taskProvider.allTasks.where((t) {
          final d = DateTime(
              t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return d == selDay;
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final pendingDayTasks =
            dayTasks.where((t) => !t.isCompleted).toList();
        final activeFocusTask =
            pendingDayTasks.isNotEmpty ? pendingDayTasks.first : null;

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── AppBar ─────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar()),

                // ── Month + Title ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy')
                              .format(_weekStart)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color:
                                AppTheme.primaryColor.withOpacity(0.55),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Weekly Focus',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge,
                            ),
                            const Spacer(),
                            _WeekNavButton(
                              icon: Icons.chevron_left,
                              onTap: _prevWeek,
                            ),
                            const SizedBox(width: 4),
                            _WeekNavButton(
                              icon: Icons.chevron_right,
                              onTap: _nextWeek,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Day Selector ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final date =
                            _weekStart.add(Duration(days: i));
                        final isSelected = i == _selectedDayIndex;
                        final isToday = _isSameDay(date, DateTime.now());
                        const labels = [
                          'MON','TUE','WED','THU','FRI','SAT','SUN'
                        ];

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDayIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: isToday && !isSelected
                                  ? Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryColor
                                            .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.primaryDark,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ── Active Focus Card ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: activeFocusTask != null
                        ? _ActiveFocusCard(
                            task: activeFocusTask,
                            onComplete: () => taskProvider
                                .toggleTaskCompletion(activeFocusTask.id),
                            onDetails: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (_) => AddEditTaskScreen(
                                      task: activeFocusTask)),
                            ),
                          )
                        : _NoFocusCard(date: selDay),
                  ),
                ),

                // ── Scheduled Timeline Label ───────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      'Scheduled Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                ),

                // ── Timeline Items ─────────────────────────────────
                dayTasks.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: Text(
                              'No tasks scheduled',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.primaryColor
                                    .withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 10),
                            child: _TimelineItem(
                              task: dayTasks[i],
                              onComplete: () => taskProvider
                                  .toggleTaskCompletion(dayTasks[i].id),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (_) => AddEditTaskScreen(
                                        task: dayTasks[i])),
                              ),
                            ),
                          ),
                          childCount: dayTasks.length,
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Icon(Icons.menu,
              color: AppTheme.primaryColor.withOpacity(0.7), size: 24),
          const SizedBox(width: 12),
          Text(
            'Mindful Flow',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          Icon(Icons.account_circle_outlined,
              color: AppTheme.primaryColor, size: 28),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── Week Nav Button ────────────────────────────────────────────────────────
class _WeekNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _WeekNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
    );
  }
}

// ─── Active Focus Card ──────────────────────────────────────────────────────
class _ActiveFocusCard extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onDetails;

  const _ActiveFocusCard({
    required this.task,
    required this.onComplete,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE FOCUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Today, ${DateFormat('h:mm a').format(task.dueDate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            task.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryDark,
              height: 1.15,
            ),
          ),
          if (task.description?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              task.description!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor.withOpacity(0.65),
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onComplete,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Text(
                        'Complete Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onDetails,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text(
                      'Details',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoFocusCard extends StatelessWidget {
  final DateTime date;
  const _NoFocusCard({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline,
                size: 40,
                color: AppTheme.primaryColor.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'All clear for ${DateFormat('MMMM d').format(date)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Timeline Item ──────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.task,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('h:mm').format(task.dueDate),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : AppTheme.primaryColor,
                  ),
                ),
                Text(
                  DateFormat('a').format(task.dueDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onComplete,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? AppTheme.primaryColor
                              : AppTheme.primaryColor.withOpacity(0.25),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? Colors.grey
                                : AppTheme.primaryDark,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: Colors.grey,
                          ),
                        ),
                        if (task.description?.isNotEmpty == true)
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (task.category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              task.category.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor.withOpacity(0.5),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert,
                        size: 18,
                        color: AppTheme.primaryColor.withOpacity(0.4)),
                    onPressed: onTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}