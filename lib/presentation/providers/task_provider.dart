// lib/presentation/providers/task_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/hive_models.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/notification/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repo = TaskRepository();
  final NotificationService _notifications = NotificationService.instance;

  List<Task> _allTasks = [];
  bool _isLoading = false;

  // ─── Getters ────────────────────────────────────────────────────────────────
  List<Task> get allTasks => List.unmodifiable(_allTasks);
  List<Task> get tasks => List.unmodifiable(_allTasks);
  bool get isLoading => _isLoading;

  List<Task> get pendingTasks {
    final result = _allTasks.where((t) => !t.isCompleted).toList();
    result.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return result;
  }

  List<Task> get completedTasks {
    final result = _allTasks.where((t) => t.isCompleted).toList();
    result.sort((a, b) => (b.completedDate ?? DateTime.now())
        .compareTo(a.completedDate ?? DateTime.now()));
    return result;
  }

  TaskProvider() {
    _init();
  }

  // ─── Initialize ────────────────────────────────────────────────────────────
  Future<void> _init() async {
    _isLoading = true;
    await _repo.initialize();
    // Always reload fresh from DB
    _allTasks = List<Task>.from(_repo.getAllTasks());
    _isLoading = false;
    notifyListeners();
  }

  // ─── Reload from DB (call this to force sync) ───────────────────────────────
  Future<void> reload() async {
    _allTasks = List<Task>.from(_repo.getAllTasks());
    notifyListeners();
  }

  // ─── Add Task ───────────────────────────────────────────────────────────────
  Future<void> addTask(Task task) async {
    await _repo.addTask(task);
    // Create new list so Provider detects the change
    _allTasks = List<Task>.from(_allTasks)..add(task);
    _scheduleNotificationsForTask(task);
    notifyListeners();
  }

  // ─── Update Task ────────────────────────────────────────────────────────────
  Future<void> updateTask(Task task) async {
    await _repo.updateTask(task);

    // Replace in-memory with new list reference
    final newList = List<Task>.from(_allTasks);
    final idx = newList.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      newList[idx] = task;
    }
    _allTasks = newList;

    // Cancel old notifications, schedule new ones
    await _notifications.cancelNotification(task.id.hashCode);
    await _notifications.cancelNotification(task.id.hashCode + 1);
    if (!task.isCompleted) {
      _scheduleNotificationsForTask(task);
    }

    notifyListeners();
  }

  // ─── Delete Task (FIXED) ────────────────────────────────────────────────────
  Future<void> deleteTask(String id) async {
    // Remove from DB first
    await _repo.deleteTask(id);

    // Create a completely new list without the deleted item
    // This is the fix — mutating the old list doesn't trigger Provider rebuild
    _allTasks = _allTasks.where((t) => t.id != id).toList();

    // Cancel notifications
    await _notifications.cancelNotification(id.hashCode);
    await _notifications.cancelNotification(id.hashCode + 1);

    // Force notify
    notifyListeners();
  }

  // ─── Toggle Completion ──────────────────────────────────────────────────────
  Future<void> toggleTaskCompletion(String id) async {
    final idx = _allTasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final task = _allTasks[idx];
    final nowCompleted = !task.isCompleted;

    final updated = task.copyWith(
      isCompleted: nowCompleted,
      completedDate: nowCompleted ? DateTime.now() : null,
    );

    await _repo.updateTask(updated);

    // New list reference
    final newList = List<Task>.from(_allTasks);
    newList[idx] = updated;
    _allTasks = newList;

    // Cancel alarm if completed
    if (nowCompleted) {
      await _notifications.cancelNotification(id.hashCode);
      await _notifications.cancelNotification(id.hashCode + 1);
    }

    notifyListeners();
  }

  // ─── Clear Completed ────────────────────────────────────────────────────────
  Future<void> clearCompletedTasks() async {
    final completedIds = _allTasks
        .where((t) => t.isCompleted)
        .map((t) => t.id)
        .toList();

    for (final id in completedIds) {
      await _repo.deleteTask(id);
      await _notifications.cancelNotification(id.hashCode);
      await _notifications.cancelNotification(id.hashCode + 1);
    }

    // New list with only pending tasks
    _allTasks = _allTasks.where((t) => !t.isCompleted).toList();
    notifyListeners();
  }

  // ─── Category / Tag helpers ─────────────────────────────────────────────────
  List<Task> getTasksByCategory(String category) =>
      _allTasks
          .where((t) => t.category.toLowerCase() == category.toLowerCase())
          .toList();

  List<Task> getTasksForWeek(DateTime date) => _repo.getTasksForWeek(date);

  List<Task> getCompletedTasksForDate(DateTime date) =>
      _repo.getCompletedTasksForDate(date);

  int getCompletedCountForDate(DateTime date) =>
      getCompletedTasksForDate(date).length;

  List<int> getLast7DaysCompletion() => _repo.getLast7DaysCompletion();

  List<String> getAllTags() => _repo.getAllTags();

  List<Task> getTasksByTag(String tag) =>
      _allTasks.where((t) => t.tags.contains(tag)).toList();

  Map<String, int> getCompletionStatsByCategory() =>
      _repo.getCompletionStatsByCategory();

  int getTotalCompletedCount() => completedTasks.length;

  // ─── Subtask helpers ────────────────────────────────────────────────────────
  Future<void> addSubtaskToTask(String taskId, Subtask subtask) async {
    final idx = _allTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _allTasks[idx];
    task.addSubtask(subtask);
    await _repo.updateTask(task);
    _allTasks = List<Task>.from(_allTasks);
    notifyListeners();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final idx = _allTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _allTasks[idx];
    task.toggleSubtask(subtaskId);
    await _repo.updateTask(task);
    _allTasks = List<Task>.from(_allTasks);
    notifyListeners();
  }

  Future<void> removeSubtaskFromTask(String taskId, String subtaskId) async {
    final idx = _allTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _allTasks[idx];
    task.removeSubtask(subtaskId);
    await _repo.updateTask(task);
    _allTasks = List<Task>.from(_allTasks);
    notifyListeners();
  }

  // ─── Focus Mode ─────────────────────────────────────────────────────────────
  Future<void> setFocusMode(String taskId,
      {Duration duration = const Duration(minutes: 25)}) async {
    final idx = _allTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _allTasks[idx];
    task.enableFocusMode(duration: duration);
    await _repo.updateTask(task);
    _allTasks = List<Task>.from(_allTasks);
    notifyListeners();
  }

  Future<void> clearFocusMode(String taskId) async {
    final idx = _allTasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final task = _allTasks[idx];
    task.disableFocusMode();
    await _repo.updateTask(task);
    _allTasks = List<Task>.from(_allTasks);
    notifyListeners();
  }

  List<Task> getFocusedTasks() =>
      _allTasks.where((t) => t.isInFocusMode).toList();

  // ─── Notification Scheduling ────────────────────────────────────────────────
  void _scheduleNotificationsForTask(Task task) {
    if (task.isCompleted) return;

    // Reminder notification
    if (task.hasReminder && task.reminderMinutesBefore > 0) {
      final reminderTime = task.dueDate
          .subtract(Duration(minutes: task.reminderMinutesBefore));
      if (reminderTime.isAfter(DateTime.now())) {
        _notifications.scheduleNotification(
          id: task.id.hashCode,
          title: '⏰ Reminder: ${task.title}',
          body: task.reminderMinutesBefore == 1
              ? 'Due in 1 minute!'
              : 'Due in ${task.reminderMinutesBefore} minutes',
          scheduledDate: reminderTime,
          payload: task.id,
        );
      }
    }

    // Alarm at exact time
    if (task.hasAlarm && task.dueDate.isAfter(DateTime.now())) {
      _notifications.scheduleNotification(
        id: task.id.hashCode + 1,
        title: '🔔 Task Due: ${task.title}',
        body: task.description?.isNotEmpty == true
            ? task.description!
            : 'Time to complete this task!',
        scheduledDate: task.dueDate,
        payload: task.id,
      );
    }
  }
}