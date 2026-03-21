// lib/presentation/screens/my_lists_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/hive_models.dart';
import '../providers/task_provider.dart';

class MyListsScreen extends StatefulWidget {
  const MyListsScreen({Key? key}) : super(key: key);

  @override
  State<MyListsScreen> createState() => _MyListsScreenState();
}

class _MyListsScreenState extends State<MyListsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Category metadata
  static const Map<String, Map<String, dynamic>> _categoryMeta = {
    'work': {
      'icon': Icons.work,
      'label': 'Work',
      'description': 'Projects & professional tasks',
    },
    'personal': {
      'icon': Icons.favorite,
      'label': 'Personal',
      'description': 'Self-care & hobbies',
    },
    'shopping': {
      'icon': Icons.shopping_cart,
      'label': 'Shopping',
      'description': 'Tech & Home',
    },
    'groceries': {
      'icon': Icons.shopping_basket,
      'label': 'Groceries',
      'description': 'Weekly restock list',
    },
    'health': {
      'icon': Icons.favorite_border,
      'label': 'Health',
      'description': 'Wellness & fitness',
    },
    'ideas': {
      'icon': Icons.lightbulb,
      'label': 'Ideas',
      'description': 'Brainstorming board',
    },
  };

  void _showCreateListDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'personal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Create New List'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'List Name',
                    hintText: 'e.g., Work Projects',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration:
                      const InputDecoration(labelText: 'Category Icon'),
                  items: _categoryMeta.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Icon(
                                    e.value['icon'] as IconData,
                                    size: 18,
                                    color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(e.value['label'] as String),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDlgState(() => selectedCategory = v ?? 'personal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  // Categories are implicit from tasks — just close
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'List "${nameCtrl.text.trim()}" created!'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        // Group pending tasks by category
        final pendingTasks =
            taskProvider.allTasks.where((t) => !t.isCompleted).toList();

        final Map<String, List<Task>> grouped = {};
        for (final task in pendingTasks) {
          final cat = task.category.isEmpty ? 'personal' : task.category;
          grouped.putIfAbsent(cat, () => []).add(task);
        }

        // Apply search filter
        Map<String, List<Task>> filtered = {};
        if (_searchQuery.isEmpty) {
          filtered = grouped;
        } else {
          final q = _searchQuery.toLowerCase();
          grouped.forEach((cat, tasks) {
            if (cat.toLowerCase().contains(q)) {
              filtered[cat] = tasks;
            } else {
              final matching = tasks
                  .where((t) => t.title.toLowerCase().contains(q))
                  .toList();
              if (matching.isNotEmpty) filtered[cat] = matching;
            }
          });
        }

        // Sort: biggest category first (featured)
        final sortedEntries = filtered.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));

        // Recent activity: last 3 completed
        final recentActivity = taskProvider.completedTasks
            .where((t) => t.completedDate != null)
            .toList()
          ..sort((a, b) =>
              b.completedDate!.compareTo(a.completedDate!));
        final recentSlice = recentActivity.take(5).toList();

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── AppBar ────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildAppBar()),

                // ── Header ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Lists',
                            style:
                                Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 4),
                        Text(
                          'Organize your flow by categories',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                AppTheme.primaryColor.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Search ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search lists...',
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

                // ── Create List Button ────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateListDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create List'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Featured Card ─────────────────────────────────────
                if (sortedEntries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _FeaturedListCard(
                        category: sortedEntries.first.key,
                        tasks: sortedEntries.first.value,
                      ),
                    ),
                  ),

                // ── Other Cards ───────────────────────────────────────
                if (sortedEntries.length > 1)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final entry = sortedEntries[i + 1];
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _ListCard(
                            category: entry.key,
                            tasks: entry.value,
                          ),
                        );
                      },
                      childCount: sortedEntries.length - 1,
                    ),
                  ),

                // ── Add Category ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: GestureDetector(
                      onTap: _showCreateListDialog,
                      child: Container(
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.25),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.5),
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ADD CATEGORY',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: AppTheme.primaryColor
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Recent Activity ───────────────────────────────────
                if (recentSlice.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              size: 18,
                              color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _ActivityItem(task: recentSlice[i]),
                      ),
                      childCount: recentSlice.length,
                    ),
                  ),
                ],

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
          Text(
            'My Lists',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showCreateListDialog,
          ),
        ],
      ),
    );
  }
}

// ─── Featured List Card ─────────────────────────────────────────────────────
class _FeaturedListCard extends StatelessWidget {
  final String category;
  final List<Task> tasks;

  const _FeaturedListCard(
      {required this.category, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final meta = _MyListsScreenState._categoryMeta[category.toLowerCase()] ??
        {'icon': Icons.category, 'label': category, 'description': ''};

    final todayCount = tasks.where((t) {
      final now = DateTime.now();
      final d = DateTime(
          t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return d ==
          DateTime(now.year, now.month, now.day);
    }).length;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  meta['icon'] as IconData,
                  size: 28,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryDark,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meta['label'] as String,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            todayCount > 0
                ? '$todayCount tasks due today'
                : meta['description'] as String,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'HIGH PRIORITY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Standard List Card ─────────────────────────────────────────────────────
class _ListCard extends StatelessWidget {
  final String category;
  final List<Task> tasks;

  const _ListCard({required this.category, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final meta =
        _MyListsScreenState._categoryMeta[category.toLowerCase()] ??
            {
              'icon': Icons.category,
              'label': category,
              'description': ''
            };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              meta['icon'] as IconData,
              size: 22,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta['label'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tasks.length}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Item ──────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final Task task;
  const _ActivityItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(task.completedDate ?? task.createdDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.cardBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle,
                size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completed "${task.title}"',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.category.isNotEmpty ? task.category[0].toUpperCase() + task.category.substring(1) : "Task"} • $timeAgo',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: AppTheme.primaryColor.withOpacity(0.3)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}