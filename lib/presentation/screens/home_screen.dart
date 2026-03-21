// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'add_edit_task_screen.dart';
import 'focus_timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTask({Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddEditTaskScreen(task: task),
      ),
    );
  }

  void _openFocusTimer(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusTimerScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        final now = DateTime.now();
        final pending = taskProvider.pendingTasks;
        final priorityTask = pending.isNotEmpty ? pending.first : null;
        final featuredTask = pending.length > 1 ? pending[1] : null;

        // Today's tasks for chronological feed
        final today = DateTime(now.year, now.month, now.day);
        var allTodayTasks = taskProvider.allTasks.where((t) {
          final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return d == today;
        }).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        // Apply search filter
        if (_searchController.text.isNotEmpty) {
          final q = _searchController.text.toLowerCase();
          allTodayTasks = allTodayTasks
              .where((t) =>
                  t.title.toLowerCase().contains(q) ||
                  (t.description?.toLowerCase().contains(q) ?? false))
              .toList();
        }

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _AppBar(),
                ),

                // ── Date + Title ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d').format(now).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: AppTheme.primaryColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Day',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    size: 14, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  '${pending.length} focus task${pending.length == 1 ? '' : 's'} remaining',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Priority Card ────────────────────────────────────────
                if (priorityTask != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _PriorityCard(
                        task: priorityTask,
                        onFocusNow: () => _openFocusTimer(priorityTask),
                        onTap: () => _openTask(task: priorityTask),
                      ),
                    ),
                  ),

                // ── Featured Secondary Card ──────────────────────────────
                if (featuredTask != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _FeaturedCard(
                        task: featuredTask,
                        onTap: () => _openTask(task: featuredTask),
                        onComplete: () =>
                            taskProvider.toggleTaskCompletion(featuredTask.id),
                        onFocus: () => _openFocusTimer(featuredTask),
                      ),
                    ),
                  ),

                // ── Search ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // ── Feed Label ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'CHRONOLOGICAL FEED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

                // ── Feed Tasks ───────────────────────────────────────────
                allTodayTasks.isEmpty
                    ? SliverToBoxAdapter(child: _EmptyFeed())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = allTodayTasks[index];
                            return _FeedTaskItem(
                              task: task,
                              onComplete: () =>
                                  taskProvider.toggleTaskCompletion(task.id),
                              onTap: () => _openTask(task: task),
                              onDelete: () => taskProvider.deleteTask(task.id),
                              onFocus: () => _openFocusTimer(task),
                            );
                          },
                          childCount: allTodayTasks.length,
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
}

// ─── App Bar ────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        children: [
          Icon(Icons.menu,
              color: AppTheme.primaryColor.withOpacity(0.7), size: 24),
          const SizedBox(width: 12),
          const Text(
            'Mindful Flow',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => IconButton(
              icon: Icon(
                themeProvider.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppTheme.primaryColor,
              ),
              onPressed: themeProvider.toggleTheme,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: AppTheme.primaryColor),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Priority Card ───────────────────────────────────────────────────────────
class _PriorityCard extends StatelessWidget {
  final Task task;
  final VoidCallback onFocusNow;
  final VoidCallback onTap;

  const _PriorityCard({
    required this.task,
    required this.onFocusNow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'PRIORITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14,
                    color: AppTheme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 5),
                Text(
                  DateFormat('h:mm a').format(task.dueDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.category_outlined,
                    size: 14,
                    color: AppTheme.primaryColor.withOpacity(0.7)),
                const SizedBox(width: 5),
                Text(
                  task.category.isNotEmpty
                      ? task.category[0].toUpperCase() +
                          task.category.substring(1)
                      : 'Task',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Focus Now button — navigates to timer
            GestureDetector(
              onTap: onFocusNow,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Focus Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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

// ─── Featured Secondary Card ─────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onFocus;

  const _FeaturedCard({
    required this.task,
    required this.onTap,
    required this.onComplete,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                const Spacer(),
                // Focus button
                GestureDetector(
                  onTap: onFocus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 13, color: AppTheme.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Focus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Complete button
                GestureDetector(
                  onTap: onComplete,
                  child: Icon(
                    task.isCompleted
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.isCompleted
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withOpacity(0.3),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
              ),
            ),
            if (task.description?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primaryColor.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: task.tags
                    .take(3)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Feed Task Item ───────────────────────────────────────────────────────────
class _FeedTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFocus;

  const _FeedTaskItem({
    required this.task,
    required this.onComplete,
    required this.onTap,
    required this.onDelete,
    required this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.danger,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time
            SizedBox(
              width: 48,
              child: Text(
                DateFormat('HH:mm').format(task.dueDate),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor
                      .withOpacity(task.isCompleted ? 0.4 : 0.8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Card
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: task.isCompleted
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
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
                                  : AppTheme.primaryColor.withOpacity(0.3),
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
                      // Content
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
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.5),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (task.category.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    task.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Focus / more menu
                      if (!task.isCompleted)
                        GestureDetector(
                          onTap: onFocus,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.timer_outlined,
                                size: 16, color: AppTheme.primaryColor),
                          ),
                        )
                      else
                        Icon(
                          _categoryIcon(task.category),
                          size: 16,
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'health':
        return Icons.favorite_outline;
      case 'personal':
        return Icons.person_outline;
      case 'ideas':
        return Icons.lightbulb_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ─── Empty Feed ───────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: AppTheme.primaryColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No tasks for today',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.primaryColor.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}