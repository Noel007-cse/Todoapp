// lib/presentation/providers/user_provider.dart — XP, Level, Achievements

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/local/hive_models.dart';

class UserProvider extends ChangeNotifier {
  late Box<UserProfile> _profileBox;
  late Box<MoodEntry> _moodBox;
  late Box<JournalEntry> _journalBox;
  UserProfile _profile = UserProfile();

  UserProfile get profile => _profile;
  List<MoodEntry> get moodHistory {
    try {
      return _moodBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  List<JournalEntry> get journalEntries {
    try {
      return _journalBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {
      return [];
    }
  }

  // Achievement definitions
  static const Map<String, Map<String, String>> achievementDefs = {
    'early_bird': {
      'name': 'Early Bird',
      'desc': 'Complete a task before 7am',
      'icon': '🌅'
    },
    'deep_worker': {
      'name': 'Deep Worker',
      'desc': '90-min focus session',
      'icon': '⚡'
    },
    'unstoppable': {
      'name': 'Unstoppable',
      'desc': '30-day streak',
      'icon': '🔥'
    },
    'first_task': {
      'name': 'First Step',
      'desc': 'Complete your first task',
      'icon': '👣'
    },
    'five_streak': {
      'name': 'On Fire',
      'desc': '5-day streak',
      'icon': '🔥'
    },
    'ten_tasks': {
      'name': 'Decathlon',
      'desc': '10 tasks in one day',
      'icon': '🏆'
    },
    'century': {
      'name': 'Centurion',
      'desc': '100 total tasks',
      'icon': '💯'
    },
    'focus_master': {
      'name': 'Focus Master',
      'desc': '500 focus minutes',
      'icon': '🧘'
    },
    'habit_hero': {
      'name': 'Habit Hero',
      'desc': '7-day habit streak',
      'icon': '💪'
    },
    'flow_state': {
      'name': 'Flow State',
      'desc': 'Level 8 achieved',
      'icon': '🌊'
    },
    'night_owl': {
      'name': 'Night Owl',
      'desc': 'Complete task after 11pm',
      'icon': '🦉'
    },
    'organiser': {
      'name': 'Organiser',
      'desc': 'Use 5 categories',
      'icon': '📋'
    },
    'mindful': {
      'name': 'Mindful',
      'desc': 'Log mood 7 days in a row',
      'icon': '🧠'
    },
    'writer': {
      'name': 'Writer',
      'desc': 'Write 10 journal entries',
      'icon': '✍️'
    },
    'consistent': {
      'name': 'Consistent',
      'desc': '14-day streak',
      'icon': '📈'
    },
    'week_warrior': {
      'name': 'Week Warrior',
      'desc': 'Complete all tasks for a week',
      'icon': '⚔️'
    },
    'social': {
      'name': 'Social',
      'desc': 'Share an achievement',
      'icon': '🤝'
    },
    'explorer': {
      'name': 'Explorer',
      'desc': 'Try all app features',
      'icon': '🧭'
    },
    'marathon': {
      'name': 'Marathon',
      'desc': '1000 total tasks',
      'icon': '🏃'
    },
    'zen_master': {
      'name': 'Zen Master',
      'desc': '10 breathing exercises',
      'icon': '☯️'
    },
  };

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    _profileBox = await Hive.openBox<UserProfile>('user_profile');
    _moodBox = await Hive.openBox<MoodEntry>('mood_entries');
    _journalBox = await Hive.openBox<JournalEntry>('journal_entries');

    if (_profileBox.isEmpty) {
      _profile = UserProfile();
      await _profileBox.put('profile', _profile);
    } else {
      _profile = _profileBox.get('profile') ?? UserProfile();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    await _profileBox.put('profile', _profile);
    notifyListeners();
  }

  // ── XP & Levelling ────────────────────────────────────────────────────────
  Future<void> awardXP(int amount) async {
    _profile.addXP(amount);
    await _save();
    _checkLevelAchievements();
  }

  Future<void> onTaskCompleted({
    required String priority,
    required int subtaskCount,
  }) async {
    int xp = 10; // base
    if (priority == 'high') xp += 15;
    if (priority == 'medium') xp += 5;
    xp += subtaskCount * 3;

    _profile.totalTasksCompleted++;
    _profile.addXP(xp);

    // Check achievements
    if (_profile.totalTasksCompleted == 1) unlockAchievement('first_task');
    if (_profile.totalTasksCompleted >= 100) unlockAchievement('century');
    if (_profile.totalTasksCompleted >= 1000) unlockAchievement('marathon');

    final hour = DateTime.now().hour;
    if (hour < 7) unlockAchievement('early_bird');
    if (hour >= 23) unlockAchievement('night_owl');

    await _save();
  }

  Future<void> addFocusMinutes(int minutes) async {
    _profile.totalFocusMinutes += minutes;
    if (_profile.totalFocusMinutes >= 500) unlockAchievement('focus_master');
    if (minutes >= 90) unlockAchievement('deep_worker');
    await _save();
  }

  Future<void> updateStreak(int streak) async {
    _profile.currentStreak = streak;
    if (streak > _profile.bestStreak) _profile.bestStreak = streak;
    if (streak >= 5) unlockAchievement('five_streak');
    if (streak >= 14) unlockAchievement('consistent');
    if (streak >= 30) unlockAchievement('unstoppable');
    await _save();
  }

  void _checkLevelAchievements() {
    if (_profile.level >= 8) unlockAchievement('flow_state');
  }

  void unlockAchievement(String id) {
    if (!_profile.achievements.contains(id)) {
      _profile.achievements.add(id);
      notifyListeners();
    }
  }

  bool hasAchievement(String id) => _profile.achievements.contains(id);

  // ── Mood ───────────────────────────────────────────────────────────────────
  Future<void> logMood(int mood, {String? note}) async {
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: mood,
      note: note,
      date: DateTime.now(),
    );
    await _moodBox.put(entry.id, entry);
    notifyListeners();
  }

  MoodEntry? get todaysMood {
    final now = DateTime.now();
    try {
      return _moodBox.values.cast<MoodEntry?>().firstWhere(
            (e) =>
                e != null &&
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day,
            orElse: () => null,
          );
    } catch (_) {
      return null;
    }
  }

  // ── Journal ────────────────────────────────────────────────────────────────
  Future<void> addJournalEntry(String content, {int mood = 3}) async {
    final entry = JournalEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      date: DateTime.now(),
      mood: mood,
    );
    await _journalBox.put(entry.id, entry);
    if (_journalBox.length >= 10) unlockAchievement('writer');
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    _profile.name = name;
    await _save();
  }
}
