// lib/data/repositories/task_repository.dart - COMPLETE MINDFUL FLOW

import 'package:hive/hive.dart';
import '../local/hive_models.dart';

class TaskRepository {
  late Box<Task> _taskBox;
  late Box<TaskList> _listBox;

  Future<void> initialize() async {
    _taskBox = Hive.box<Task>('tasks');
    try {
      _listBox = await Hive.openBox<TaskList>('lists');
    } catch (e) {
      // Lists box might not exist yet
    }
  }

  // ===== BASIC TASK OPERATIONS =====

  Future<void> addTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskBox.delete(taskId);
  }

  Task? getTaskById(String id) {
    return _taskBox.get(id);
  }

  List<Task> getAllTasks() {
    return _taskBox.values.toList();
  }

  // ===== FILTERED QUERIES =====

  List<Task> getPendingTasks() {
    return _taskBox.values.where((task) => !task.isCompleted).toList();
  }

  List<Task> getCompletedTasks() {
    return _taskBox.values.where((task) => task.isCompleted).toList();
  }

  List<Task> getTodaysTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _taskBox.values.where((task) {
      final taskDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDay == today && !task.isCompleted;
    }).toList();
  }

  List<Task> getOverdueTasks() {
    return _taskBox.values.where((task) => task.isOverdue).toList();
  }

  // ===== DATE-BASED QUERIES =====

  List<Task> getTasksForDate(DateTime date) {
    final targetDay = DateTime(date.year, date.month, date.day);
    return _taskBox.values.where((task) {
      final taskDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      return taskDay == targetDay;
    }).toList();
  }

  List<Task> getTasksForWeek(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _taskBox.values.where((task) {
      return task.dueDate.isAfter(startOfWeek) &&
          task.dueDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  List<Task> getTasksForMonth(DateTime date) {
    return _taskBox.values.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month;
    }).toList();
  }

  // ===== CATEGORY & PRIORITY QUERIES =====

  List<Task> getTasksByCategory(String category) {
    return _taskBox.values.where((task) =>
        task.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<Task> getTasksByPriority(String priority) {
    return _taskBox.values.where((task) =>
        task.priority.toLowerCase() == priority.toLowerCase())
        .toList();
  }

  Map<String, List<Task>> getTasksByCategories() {
    final Map<String, List<Task>> categories = {};
    for (var task in _taskBox.values) {
      if (!categories.containsKey(task.category)) {
        categories[task.category] = [];
      }
      categories[task.category]!.add(task);
    }
    return categories;
  }

  // ===== TAG QUERIES =====

  List<Task> getTasksByTag(String tag) {
    return _taskBox.values.where((task) =>
        task.tags.contains(tag))
        .toList();
  }

  List<String> getAllTags() {
    final Set<String> allTags = {};
    for (var task in _taskBox.values) {
      allTags.addAll(task.tags);
    }
    return allTags.toList();
  }

  // ===== SUBTASK OPERATIONS =====

  void addSubtaskToTask(String taskId, Subtask subtask) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.addSubtask(subtask);
      _taskBox.put(taskId, task);
    }
  }

  void toggleSubtask(String taskId, String subtaskId) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.toggleSubtask(subtaskId);
      _taskBox.put(taskId, task);
    }
  }

  void removeSubtaskFromTask(String taskId, String subtaskId) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.removeSubtask(subtaskId);
      _taskBox.put(taskId, task);
    }
  }

  // ===== FOCUS MODE =====

  List<Task> getFocusedTasks() {
    return _taskBox.values.where((task) => task.isInFocusMode).toList();
  }

  void setFocusMode(String taskId, {Duration duration = const Duration(minutes: 25)}) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.enableFocusMode(duration: duration);
      _taskBox.put(taskId, task);
    }
  }

  void clearFocusMode(String taskId) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.disableFocusMode();
      _taskBox.put(taskId, task);
    }
  }

  // ===== SEARCH =====

  List<Task> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return _taskBox.values.where((task) {
      return task.title.toLowerCase().contains(lowerQuery) ||
          (task.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // ===== ARCHIVE & STATISTICS =====

  int getTotalCompletedCount() {
    return _taskBox.values.where((task) => task.isCompleted).length;
  }

  int getTotalTasksCount() {
    return _taskBox.length;
  }

  int getCompletedCountForMonth(DateTime month) {
    return _taskBox.values.where((task) {
      return task.isCompleted &&
          task.completedDate != null &&
          task.completedDate!.year == month.year &&
          task.completedDate!.month == month.month;
    }).length;
  }

  List<Task> getCompletedTasksForDate(DateTime date) {
    final targetDay = DateTime(date.year, date.month, date.day);
    return _taskBox.values.where((task) {
      if (!task.isCompleted || task.completedDate == null) return false;
      final completedDay = DateTime(
        task.completedDate!.year,
        task.completedDate!.month,
        task.completedDate!.day,
      );
      return completedDay == targetDay;
    }).toList();
  }

  Map<String, int> getCompletionStatsByCategory() {
    final stats = <String, int>{};
    for (var task in _taskBox.values.where((t) => t.isCompleted)) {
      stats[task.category] = (stats[task.category] ?? 0) + 1;
    }
    return stats;
  }

  double getCompletionPercentage() {
    if (_taskBox.isEmpty) return 0;
    final completed = _taskBox.values.where((t) => t.isCompleted).length;
    return (completed / _taskBox.length) * 100;
  }

  // ===== LAST 7 DAYS COMPLETION =====

  List<int> getLast7DaysCompletion() {
    final now = DateTime.now();
    final List<int> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final count = getCompletedTasksForDate(date).length;
      data.add(count);
    }

    return data;
  }

  // ===== CLEAR OPERATIONS =====

  Future<void> clearAllTasks() async {
    await _taskBox.clear();
  }

  Future<void> clearCompletedTasks() async {
    final completedIds = _taskBox.values
        .where((task) => task.isCompleted)
        .map((task) => task.id)
        .toList();

    for (var id in completedIds) {
      await _taskBox.delete(id);
    }
  }

  // ===== LIST/CATEGORY OPERATIONS =====

  Future<void> addList(TaskList list) async {
    await _listBox.put(list.id, list);
  }

  Future<void> updateList(TaskList list) async {
    await _listBox.put(list.id, list);
  }

  Future<void> deleteList(String listId) async {
    await _listBox.delete(listId);
  }

  TaskList? getListById(String id) {
    return _listBox.get(id);
  }

  List<TaskList> getAllLists() {
    return _listBox.values.toList();
  }

  List<TaskList> getPinnedLists() {
    return _listBox.values.where((list) => list.isPinned).toList();
  }
}