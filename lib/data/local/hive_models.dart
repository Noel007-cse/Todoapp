// lib/data/local/hive_models.dart - COMPLETE MINDFUL FLOW MODEL

import 'package:hive/hive.dart';

part 'hive_models.g.dart';

// ===== SUBTASK MODEL =====
@HiveType(typeId: 1)
class Subtask extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late bool isCompleted;

  @HiveField(3)
  late DateTime createdDate;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.createdDate,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdDate,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

// ===== TASK MODEL =====
@HiveType(typeId: 0)
class Task extends HiveObject {
  // ===== BASIC FIELDS =====
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late DateTime dueDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  late DateTime createdDate;

  @HiveField(6)
  DateTime? completedDate;

  @HiveField(7)
  bool hasReminder;

  @HiveField(8)
  int reminderMinutesBefore;

  @HiveField(9)
  bool hasAlarm;

  @HiveField(10)
  String category;

  // ===== ADVANCED FIELDS =====
  @HiveField(11)
  late List<Subtask> subtasks; // Breakdown/sub-tasks

  @HiveField(12)
  late List<String> tags; // Tags/classification

  @HiveField(13)
  String priority; // 'low', 'medium', 'high'

  @HiveField(14)
  bool isFocused; // Focus mode flag

  @HiveField(15)
  DateTime? focusedUntil; // Focus duration end time

  @HiveField(16)
  late List<String> recentActivity; // Activity log

  @HiveField(17)
  int completionPercentage; // % of subtasks completed

  // ===== CONSTRUCTOR =====
  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    required this.createdDate,
    this.completedDate,
    this.hasReminder = true,
    this.reminderMinutesBefore = 15,
    this.hasAlarm = true,
    this.category = 'personal',
    List<Subtask>? subtasks,
    List<String>? tags,
    this.priority = 'medium',
    this.isFocused = false,
    this.focusedUntil,
    List<String>? recentActivity,
    this.completionPercentage = 0,
  }) {
    this.subtasks = subtasks ?? [];
    this.tags = tags ?? [];
    this.recentActivity = recentActivity ?? [];
  }

  // ===== COPY WITH METHOD =====
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdDate,
    DateTime? completedDate,
    bool? hasReminder,
    int? reminderMinutesBefore,
    bool? hasAlarm,
    String? category,
    List<Subtask>? subtasks,
    List<String>? tags,
    String? priority,
    bool? isFocused,
    DateTime? focusedUntil,
    List<String>? recentActivity,
    int? completionPercentage,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdDate: createdDate ?? this.createdDate,
      completedDate: completedDate ?? this.completedDate,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      isFocused: isFocused ?? this.isFocused,
      focusedUntil: focusedUntil ?? this.focusedUntil,
      recentActivity: recentActivity ?? this.recentActivity,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  // ===== GETTERS & CALCULATIONS =====

  /// Check if task is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Get time remaining until due date
  Duration get timeRemaining {
    return dueDate.difference(DateTime.now());
  }

  /// Calculate subtask completion percentage
  int calculateSubtaskCompletion() {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return ((completed / subtasks.length) * 100).toInt();
  }

  /// Get priority color (for UI)
  String getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return '#EF4444'; // Red
      case 'medium':
        return '#F59E0B'; // Amber
      case 'low':
        return '#10B981'; // Green
      default:
        return '#0A6E7F'; // Teal
    }
  }

  /// Check if any subtask exists
  bool get hasSubtasks => subtasks.isNotEmpty;

  /// Check if all subtasks completed
  bool get allSubtasksCompleted {
    if (subtasks.isEmpty) return true;
    return subtasks.every((s) => s.isCompleted);
  }

  /// Get formatted due date string
  String getFormattedDueDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay == today) {
      return 'Today';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${dueDate.month}/${dueDate.day}/${dueDate.year}';
    }
  }

  /// Get time remaining as readable string
  String getReadableTimeRemaining() {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';

    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays} days left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hours left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minutes left';
    } else {
      return 'Due soon';
    }
  }

  /// Add subtask
  void addSubtask(Subtask subtask) {
    subtasks.add(subtask);
    updateCompletion();
  }

  /// Toggle subtask completion
  void toggleSubtask(String subtaskId) {
    for (var i = 0; i < subtasks.length; i++) {
      if (subtasks[i].id == subtaskId) {
        subtasks[i].isCompleted = !subtasks[i].isCompleted;
        break;
      }
    }
    updateCompletion();
  }

  /// Remove subtask
  void removeSubtask(String subtaskId) {
    subtasks.removeWhere((s) => s.id == subtaskId);
    updateCompletion();
  }

  /// Update completion percentage
  void updateCompletion() {
    completionPercentage = calculateSubtaskCompletion();
  }

  /// Add tag
  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
    }
  }

  /// Remove tag
  void removeTag(String tag) {
    tags.remove(tag);
  }

  /// Add activity log entry
  void addActivity(String activity) {
    recentActivity.add('${DateTime.now().toIso8601String()}: $activity');
  }

  /// Enable focus mode
  void enableFocusMode({Duration duration = const Duration(minutes: 25)}) {
    isFocused = true;
    focusedUntil = DateTime.now().add(duration);
    addActivity('Entered focus mode');
  }

  /// Disable focus mode
  void disableFocusMode() {
    isFocused = false;
    focusedUntil = null;
    addActivity('Exited focus mode');
  }

  /// Check if currently in focus mode
  bool get isInFocusMode {
    if (!isFocused || focusedUntil == null) return false;
    return DateTime.now().isBefore(focusedUntil!);
  }

  /// Get focus time remaining
  Duration? getFocusTimeRemaining() {
    if (!isInFocusMode) return null;
    return focusedUntil!.difference(DateTime.now());
  }
}

// ===== LIST/CATEGORY MODEL =====
@HiveType(typeId: 2)
class TaskList extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  late String category;

  @HiveField(4)
  String icon; // Icon name

  @HiveField(5)
  String color; // Hex color code

  @HiveField(6)
  late DateTime createdDate;

  @HiveField(7)
  int taskCount; // Number of tasks in this list

  @HiveField(8)
  bool isPinned; // Pin to top

  TaskList({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.icon = 'category',
    this.color = '#0A6E7F',
    required this.createdDate,
    this.taskCount = 0,
    this.isPinned = false,
  });

  TaskList copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    String? color,
    DateTime? createdDate,
    int? taskCount,
    bool? isPinned,
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdDate: createdDate ?? this.createdDate,
      taskCount: taskCount ?? this.taskCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}