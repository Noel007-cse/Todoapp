// lib/data/local/hive_models.dart — Mindful Flow Complete Models

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

  @HiveField(11)
  late List<Subtask> subtasks;

  @HiveField(12)
  late List<String> tags;

  @HiveField(13)
  String priority;

  @HiveField(14)
  bool isFocused;

  @HiveField(15)
  DateTime? focusedUntil;

  @HiveField(16)
  late List<String> recentActivity;

  @HiveField(17)
  int completionPercentage;

  // ===== NEW FIELDS (v2) =====
  @HiveField(18)
  int energyCost; // 1-5

  @HiveField(19)
  int estimatedMinutes;

  @HiveField(20)
  int actualMinutes;

  @HiveField(21)
  int focusSessionCount;

  @HiveField(22)
  int postponeCount;

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
    this.energyCost = 2,
    this.estimatedMinutes = 30,
    this.actualMinutes = 0,
    this.focusSessionCount = 0,
    this.postponeCount = 0,
  }) {
    this.subtasks = subtasks ?? [];
    this.tags = tags ?? [];
    this.recentActivity = recentActivity ?? [];
  }

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
    int? energyCost,
    int? estimatedMinutes,
    int? actualMinutes,
    int? focusSessionCount,
    int? postponeCount,
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
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      category: category ?? this.category,
      subtasks: subtasks ?? this.subtasks,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      isFocused: isFocused ?? this.isFocused,
      focusedUntil: focusedUntil ?? this.focusedUntil,
      recentActivity: recentActivity ?? this.recentActivity,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      energyCost: energyCost ?? this.energyCost,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      focusSessionCount: focusSessionCount ?? this.focusSessionCount,
      postponeCount: postponeCount ?? this.postponeCount,
    );
  }

  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  Duration get timeRemaining => dueDate.difference(DateTime.now());

  int calculateSubtaskCompletion() {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return ((completed / subtasks.length) * 100).toInt();
  }

  String getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return '#FF5252';
      case 'medium':
        return '#FF9800';
      case 'low':
        return '#00E676';
      default:
        return '#00D4AA';
    }
  }

  bool get hasSubtasks => subtasks.isNotEmpty;

  bool get allSubtasksCompleted {
    if (subtasks.isEmpty) return true;
    return subtasks.every((s) => s.isCompleted);
  }

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

  String getReadableTimeRemaining() {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';

    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m left';
    } else {
      return 'Due now';
    }
  }

  void addSubtask(Subtask subtask) {
    subtasks.add(subtask);
    updateCompletion();
  }

  void toggleSubtask(String subtaskId) {
    for (var i = 0; i < subtasks.length; i++) {
      if (subtasks[i].id == subtaskId) {
        subtasks[i].isCompleted = !subtasks[i].isCompleted;
        break;
      }
    }
    updateCompletion();
  }

  void removeSubtask(String subtaskId) {
    subtasks.removeWhere((s) => s.id == subtaskId);
    updateCompletion();
  }

  void updateCompletion() {
    completionPercentage = calculateSubtaskCompletion();
  }

  void addTag(String tag) {
    if (!tags.contains(tag)) tags.add(tag);
  }

  void removeTag(String tag) => tags.remove(tag);

  void addActivity(String activity) {
    recentActivity.add('${DateTime.now().toIso8601String()}: $activity');
  }

  void enableFocusMode({Duration duration = const Duration(minutes: 25)}) {
    isFocused = true;
    focusedUntil = DateTime.now().add(duration);
    addActivity('Entered focus mode');
  }

  void disableFocusMode() {
    isFocused = false;
    focusedUntil = null;
    addActivity('Exited focus mode');
  }

  bool get isInFocusMode {
    if (!isFocused || focusedUntil == null) return false;
    return DateTime.now().isBefore(focusedUntil!);
  }

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
  String icon;

  @HiveField(5)
  String color;

  @HiveField(6)
  late DateTime createdDate;

  @HiveField(7)
  int taskCount;

  @HiveField(8)
  bool isPinned;

  TaskList({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.icon = 'category',
    this.color = '#00D4AA',
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

// ===== HABIT MODEL =====
@HiveType(typeId: 3)
class Habit extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  String color;

  @HiveField(4)
  String frequency; // daily, weekdays, custom

  @HiveField(5)
  int targetDaysPerWeek;

  @HiveField(6)
  late List<String> completionDates; // ISO date strings

  @HiveField(7)
  int currentStreak;

  @HiveField(8)
  int bestStreak;

  @HiveField(9)
  late DateTime createdDate;

  @HiveField(10)
  String category;

  @HiveField(11)
  late List<String> notes; // date:note pairs

  @HiveField(12)
  int order;

  Habit({
    required this.id,
    required this.name,
    this.icon = '💪',
    this.color = '#00D4AA',
    this.frequency = 'daily',
    this.targetDaysPerWeek = 7,
    List<String>? completionDates,
    this.currentStreak = 0,
    this.bestStreak = 0,
    required this.createdDate,
    this.category = 'health',
    List<String>? notes,
    this.order = 0,
  }) {
    this.completionDates = completionDates ?? [];
    this.notes = notes ?? [];
  }

  bool isCompletedForDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return completionDates.contains(dateStr);
  }

  bool get isCompletedToday => isCompletedForDate(DateTime.now());

  void toggleDate(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (completionDates.contains(dateStr)) {
      completionDates.remove(dateStr);
    } else {
      completionDates.add(dateStr);
    }
    _recalculateStreak();
  }

  void _recalculateStreak() {
    int streak = 0;
    var date = DateTime.now();
    while (true) {
      if (isCompletedForDate(date)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else if (date.day == DateTime.now().day &&
          date.month == DateTime.now().month) {
        // Today not yet completed — skip
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    currentStreak = streak;
    if (streak > bestStreak) bestStreak = streak;
  }

  double get weeklySuccessRate {
    final now = DateTime.now();
    int completed = 0;
    for (int i = 0; i < 7; i++) {
      if (isCompletedForDate(now.subtract(Duration(days: i)))) {
        completed++;
      }
    }
    return completed / targetDaysPerWeek;
  }
}

// ===== USER PROFILE MODEL =====
@HiveType(typeId: 4)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int xp;

  @HiveField(2)
  int level;

  @HiveField(3)
  int totalTasksCompleted;

  @HiveField(4)
  int totalFocusMinutes;

  @HiveField(5)
  late List<String> achievements; // badge IDs

  @HiveField(6)
  late DateTime joinDate;

  @HiveField(7)
  int currentStreak;

  @HiveField(8)
  int bestStreak;

  @HiveField(9)
  String workStyle; // planner, sprinter, explorer

  @HiveField(10)
  int sleepHourStart; // 22 = 10pm

  @HiveField(11)
  int sleepHourEnd; // 7 = 7am

  @HiveField(12)
  int bestDayTasks;

  @HiveField(13)
  int bestWeekTasks;

  UserProfile({
    this.name = 'Noel',
    this.xp = 0,
    this.level = 1,
    this.totalTasksCompleted = 0,
    this.totalFocusMinutes = 0,
    List<String>? achievements,
    DateTime? joinDate,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.workStyle = 'planner',
    this.sleepHourStart = 22,
    this.sleepHourEnd = 7,
    this.bestDayTasks = 0,
    this.bestWeekTasks = 0,
  }) {
    this.achievements = achievements ?? [];
    this.joinDate = joinDate ?? DateTime.now();
  }

  static const List<String> levelNames = [
    'Getting Started',
    'Beginner',
    'Focused',
    'Productive',
    'Efficient',
    'Expert',
    'Master',
    'Flow Master',
    'Legendary',
    'Transcendent',
  ];

  String get levelName =>
      levelNames[(level - 1).clamp(0, levelNames.length - 1)];

  int get xpForNextLevel => level * 100;

  double get xpProgress => xp / xpForNextLevel;

  void addXP(int amount) {
    xp += amount;
    while (xp >= xpForNextLevel && level < 10) {
      xp -= xpForNextLevel;
      level++;
    }
  }
}

// ===== MOOD ENTRY MODEL =====
@HiveType(typeId: 5)
class MoodEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  int mood; // 1-5

  @HiveField(2)
  String? note;

  @HiveField(3)
  late DateTime date;

  @HiveField(4)
  double productivityScore;

  MoodEntry({
    required this.id,
    this.mood = 3,
    this.note,
    required this.date,
    this.productivityScore = 0.0,
  });
}

// ===== JOURNAL ENTRY MODEL =====
@HiveType(typeId: 6)
class JournalEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String content;

  @HiveField(2)
  late DateTime date;

  @HiveField(3)
  late List<String> tags;

  @HiveField(4)
  int mood;

  JournalEntry({
    required this.id,
    required this.content,
    required this.date,
    List<String>? tags,
    this.mood = 3,
  }) {
    this.tags = tags ?? [];
  }
}

// ===== CHAT MESSAGE MODEL =====
@HiveType(typeId: 7)
class ChatMessage extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String content;

  @HiveField(2)
  bool isUser;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late List<String> actionButtons; // button labels

  ChatMessage({
    required this.id,
    required this.content,
    this.isUser = true,
    required this.timestamp,
    List<String>? actionButtons,
  }) {
    this.actionButtons = actionButtons ?? [];
  }
}