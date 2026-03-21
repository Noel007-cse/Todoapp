// lib/presentation/screens/archive_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({Key? key}) : super(key: key);

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All Time';
  String _searchQuery = '';

  static const List<String> _filters = [
    'All Time',
    'Work',
    'Health',
    'Personal',
    'Shopping',
    'Ideas',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        // Get completed tasks
        var completed = taskProvider.completedTasks.toList()
          ..sort((a, b) =>
              (b.completedDate ?? DateTime.now())
                  .compareTo(a.completedDate ?? DateTime.now()));

        // Apply category filter
        if (_selectedFilter != 'All Time') {
          completed = completed
              .where((t) =>
                  t.category.toLowerCase() ==
                  _selectedFilter.toLowerCase())
              .toList();
        }

        // Apply search
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          completed = completed
              .where((t) =>
                  t.title.toLowerCase().contains(q) ||
                  (t.description?.toLowerCase().contains(q) ?? false))
              .toList();
        }

        // Group by date
        final Map<String, List<Task>> grouped = {};
        for (final task in completed) {
          final dt = task.completedDate ?? task.dueDate;
          final key =
              DateFormat('MMMM d, yyyy').format(dt).toUpperCase();
          grouped.putIfAbsent(key, () => []).add(task);
        }

        // Stats
        final totalCompleted = taskProvider.completedTasks.length;
        final now = DateTime.now();
        final thisMonthCount = taskProvider.completedTasks
            .where((t) =>
                t.completedDate != null &&
                t.completedDate!.year == now.year &&
                t.completedDate!.month == now.month)
            .length;
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear =
            now.month == 1 ? now.year - 1 : now.year;
        final lastMonthCount = taskProvider.completedTasks
            .where((t) =>
                t.completedDate != null &&
                t.completedDate!.year == lastMonthYear &&
                t.completedDate!.month == lastMonth)
            .length;
        final pctIncrease = lastMonthCount == 0
            ? 0
            : (((thisMonthCount - lastMonthCount) / lastMonthCount) * 100)
                .round();

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── AppBar ─────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar()),

                // ── Header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Archive',
                            style:
                                Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Reflect on your progress and celebrated milestones.',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                AppTheme.primaryColor.withOpacity(0.55),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search your achievements...',
                        prefixIcon:
                            const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // ── Filters ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      itemCount: _filters.length,
                      itemBuilder: (ctx, i) {
                        final f = _filters[i];
                        final isSelected = f == _selectedFilter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedFilter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: !isSelected
                                    ? Border.all(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.15))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (isSelected) ...[
                                    Icon(Icons.check,
                                        size: 13,
                                        color: Colors.white),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    f,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Mastery Card ───────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBlue,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL MASTERY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color:
                                  AppTheme.primaryColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalCompleted',
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryDark,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tasks completed this year',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  AppTheme.primaryColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 16,
                                color: pctIncrease >= 0
                                    ? const Color(0xFF00897B)
                                    : AppTheme.danger,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$pctIncrease% more than last month',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: pctIncrease >= 0
                                      ? const Color(0xFF00897B)
                                      : AppTheme.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Completed Tasks by Date ────────────────────────
                if (grouped.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, sectionIndex) {
                        final dateKey =
                            grouped.keys.toList()[sectionIndex];
                        final tasks = grouped[dateKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  20, 24, 20, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dateKey,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 1,
                                    width: 40,
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                  ),
                                ],
                              ),
                            ),
                            ...tasks.map((task) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 10),
                                  child: _CompletedTaskCard(task: task),
                                )),
                          ],
                        );
                      },
                      childCount: grouped.length,
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 56,
                            color: AppTheme.primaryColor.withOpacity(0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'END OF RECENT HISTORY',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color:
                                  AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
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

// ─── Completed Task Card ────────────────────────────────────────────────────
class _CompletedTaskCard extends StatelessWidget {
  final Task task;
  const _CompletedTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final completedAt = task.completedDate ?? task.dueDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.cardBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A9BA8),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Color(0xFF8A9BA8),
                    decorationThickness: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
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
                    const SizedBox(width: 8),
                    Text(
                      'Completed at ${DateFormat('h:mm a').format(completedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}