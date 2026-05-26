// lib/presentation/providers/habit_provider.dart — Habit Tracking

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/hive_models.dart';

class HabitProvider extends ChangeNotifier {
  late Box<Habit> _habitBox;
  List<Habit> _habits = [];
  bool _isLoaded = false;

  List<Habit> get habits => List.unmodifiable(_habits);
  bool get isLoaded => _isLoaded;

  // Template habits for quick-add
  static final List<Map<String, String>> templates = [
    {'name': 'Hydration', 'icon': '💧', 'category': 'health'},
    {'name': 'Meditation', 'icon': '🧘', 'category': 'health'},
    {'name': 'Exercise', 'icon': '💪', 'category': 'health'},
    {'name': 'Reading', 'icon': '📚', 'category': 'learning'},
    {'name': 'Journaling', 'icon': '✍️', 'category': 'personal'},
    {'name': 'Cold Shower', 'icon': '🚿', 'category': 'health'},
    {'name': 'Gratitude', 'icon': '🙏', 'category': 'personal'},
    {'name': 'No Sugar', 'icon': '🚫', 'category': 'health'},
    {'name': 'Walk 10k Steps', 'icon': '🚶', 'category': 'health'},
    {'name': 'Sleep by 11pm', 'icon': '😴', 'category': 'health'},
    {'name': 'No Social Media', 'icon': '📵', 'category': 'personal'},
    {'name': 'Stretch', 'icon': '🤸', 'category': 'health'},
    {'name': 'Vitamins', 'icon': '💊', 'category': 'health'},
    {'name': 'Cook Meals', 'icon': '🍳', 'category': 'personal'},
    {'name': 'Practice Instrument', 'icon': '🎸', 'category': 'learning'},
    {'name': 'Language Study', 'icon': '🌍', 'category': 'learning'},
    {'name': 'Skincare Routine', 'icon': '✨', 'category': 'health'},
    {'name': 'Floss', 'icon': '🦷', 'category': 'health'},
    {'name': 'Budget Check', 'icon': '💰', 'category': 'personal'},
    {'name': 'Deep Breathing', 'icon': '🌬️', 'category': 'health'},
  ];

  HabitProvider() {
    _init();
  }

  Future<void> _init() async {
    _habitBox = await Hive.openBox<Habit>('habits');
    _habits = _habitBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> addHabit(Habit habit) async {
    habit.order = _habits.length;
    await _habitBox.put(habit.id, habit);
    _habits = _habitBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> addFromTemplate(Map<String, String> template) async {
    final habit = Habit(
      id: const Uuid().v4(),
      name: template['name']!,
      icon: template['icon']!,
      category: template['category']!,
      createdDate: DateTime.now(),
    );
    await addHabit(habit);
  }

  Future<void> toggleHabitForToday(String habitId) async {
    final habit = _habitBox.get(habitId);
    if (habit == null) return;
    habit.toggleDate(DateTime.now());
    await _habitBox.put(habitId, habit);
    _habits = _habitBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitBox.delete(habitId);
    _habits = _habitBox.values.toList()..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  // Stats
  int get totalActiveHabits => _habits.length;

  int get completedToday =>
      _habits.where((h) => h.isCompletedToday).length;

  double get todayCompletionRate =>
      _habits.isEmpty ? 0.0 : completedToday / _habits.length;

  int get longestStreak {
    if (_habits.isEmpty) return 0;
    return _habits.map((h) => h.bestStreak).reduce((a, b) => a > b ? a : b);
  }
}
