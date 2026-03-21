// lib/presentation/providers/analytics_provider.dart

import 'package:flutter/material.dart';
import '../../data/local/hive_models.dart';
import '../../data/repositories/task_repository.dart';

class AnalyticsData {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final double completionPercentage;
  final List<int> last7DaysCompletion;
  final DateTime date;

  AnalyticsData({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.completionPercentage,
    required this.last7DaysCompletion,
    required this.date,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();
  late AnalyticsData _todaysAnalytics;

  AnalyticsData get todaysAnalytics => _todaysAnalytics;

  AnalyticsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _taskRepository.initialize();
    _updateAnalytics();
  }

  /// Update analytics data
  void _updateAnalytics() {
    final allTasks = _taskRepository.getAllTasks();
    final today = DateTime.now();
    
    // Get today's tasks
    final todaysTasks = allTasks.where((t) {
      final taskDate = t.dueDate;
      return taskDate.year == today.year &&
          taskDate.month == today.month &&
          taskDate.day == today.day;
    }).toList();

    final completedToday = todaysTasks.where((t) => t.isCompleted).length;
    final totalToday = todaysTasks.length;
    final completionPercentage =
        totalToday == 0 ? 0.0 : (completedToday / totalToday) * 100;

    // Get last 7 days completion data
    final last7DaysCompletion = _getLast7DaysCompletion();

    _todaysAnalytics = AnalyticsData(
      totalTasks: totalToday,
      completedTasks: completedToday,
      pendingTasks: totalToday - completedToday,
      completionPercentage: completionPercentage,
      last7DaysCompletion: last7DaysCompletion,
      date: today,
    );

    notifyListeners();
  }

  /// Get completion data for last 7 days
  List<int> _getLast7DaysCompletion() {
    final allTasks = _taskRepository.getAllTasks();
    final completionData = <int>[];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final tasksForDay = allTasks.where((t) {
        final taskDate = t.dueDate;
        return taskDate.year == date.year &&
            taskDate.month == date.month &&
            taskDate.day == date.day &&
            t.isCompleted;
      }).length;

      completionData.add(tasksForDay);
    }

    return completionData;
  }

  /// Get completion stats for a specific date
  Map<String, int> getStatsForDate(DateTime date) {
    final allTasks = _taskRepository.getAllTasks();
    
    final tasksForDate = allTasks.where((t) {
      final taskDate = t.dueDate;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();

    final completed = tasksForDate.where((t) => t.isCompleted).length;
    final total = tasksForDate.length;

    return {
      'total': total,
      'completed': completed,
      'pending': total - completed,
    };
  }

  /// Get total productivity stats
  Map<String, dynamic> getTotalStats() {
    final allTasks = _taskRepository.getAllTasks();
    final completed = allTasks.where((t) => t.isCompleted).length;
    final total = allTasks.length;

    return {
      'total_tasks': total,
      'completed_tasks': completed,
      'pending_tasks': total - completed,
      'completion_percentage': total == 0 ? 0.0 : (completed / total) * 100,
      'average_completion_rate': _calculateAverageCompletionRate(),
    };
  }

  /// Calculate average completion rate
  double _calculateAverageCompletionRate() {
    final allTasks = _taskRepository.getAllTasks();
    if (allTasks.isEmpty) return 0.0;

    int totalDays = 0;
    double totalPercentage = 0.0;

    // Group tasks by date
    final tasksByDate = <DateTime, List<Task>>{};
    for (var task in allTasks) {
      final date = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      tasksByDate.putIfAbsent(date, () => []).add(task);
    }

    // Calculate percentage for each day
    for (var tasks in tasksByDate.values) {
      final completed = tasks.where((t) => t.isCompleted).length;
      totalPercentage += (completed / tasks.length) * 100;
      totalDays++;
    }

    return totalDays == 0 ? 0.0 : totalPercentage / totalDays;
  }

  /// Refresh analytics
  void refreshAnalytics() {
    _updateAnalytics();
  }
}