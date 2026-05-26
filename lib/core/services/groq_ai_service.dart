// lib/core/services/groq_ai_service.dart — SahayaK AI via Groq

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroqAIService {
  static final GroqAIService instance = GroqAIService._();
  GroqAIService._();

  static String get _apiKey => ApiConfig.groqApiKey;
  static String get _baseUrl => ApiConfig.groqBaseUrl;
  static String get _model => ApiConfig.groqModel;

  static const String _systemPrompt = '''
You are SahayaK, an AI productivity companion embedded in the Mindful Flow app.

Personality:
- Warm, wise, empathetic — like a supportive mentor
- Contextually aware of time of day, day of week
- Uses the user's name (Noel) naturally
- Concise but insightful — never robotic
- Celebrates wins, gently surfaces procrastinated tasks
- Speaks in short paragraphs, uses emoji sparingly

Capabilities:
- Create tasks from natural language
- Break down big goals into actionable subtasks
- Suggest optimal scheduling based on energy patterns
- Generate weekly reviews and daily briefings
- Offer mindfulness and productivity advice
- Reframe anxiety-inducing tasks into manageable steps

When creating tasks, respond with JSON in this format:
{"action": "create_task", "title": "...", "category": "...", "priority": "...", "estimatedMinutes": N}

When breaking down goals:
{"action": "breakdown", "subtasks": [{"title": "...", "estimatedMinutes": N}, ...]}

For normal conversation, just respond naturally.
Always be encouraging and supportive.
''';

  /// General chat completion
  Future<String> chat(List<Map<String, String>> messages,
      {String? additionalContext}) async {
    final systemMessages = [
      {'role': 'system', 'content': _systemPrompt},
      if (additionalContext != null)
        {'role': 'system', 'content': 'Current context: $additionalContext'},
    ];

    final allMessages = [...systemMessages, ...messages];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': allMessages,
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        return 'I\'m having a moment of reflection. Let me try again shortly. (${response.statusCode})';
      }
    } catch (e) {
      return 'I seem to be offline right now. Your tasks are safe locally — I\'ll catch up when we reconnect.';
    }
  }

  /// Generate morning briefing
  Future<String> generateBriefing({
    required String userName,
    required int pendingTasks,
    required int completedYesterday,
    required String topTaskTitle,
    required int currentStreak,
    required String dayOfWeek,
    required int hour,
  }) async {
    final prompt =
        '''Generate a personalised morning briefing for $userName.
It's $dayOfWeek morning at ${hour}:00.
They have $pendingTasks tasks today. Yesterday they completed $completedYesterday tasks.
Their top priority is: "$topTaskTitle".
Current streak: $currentStreak days.
Keep it to 2-3 sentences. Be warm and motivating. Include one actionable nudge.''';

    return await chat([
      {'role': 'user', 'content': prompt}
    ]);
  }

  /// Auto-categorise a task from natural language
  Future<Map<String, dynamic>> parseNaturalLanguage(String input) async {
    final prompt =
        '''Parse this natural language input into a structured task.
Input: "$input"
Respond ONLY with JSON: {"title": "...", "category": "work|personal|health|shopping|ideas", "priority": "low|medium|high", "estimatedMinutes": N}
No explanation, just the JSON.''';

    try {
      final response = await chat([
        {'role': 'user', 'content': prompt}
      ]);

      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      }
    } catch (_) {}

    return {
      'title': input,
      'category': 'personal',
      'priority': 'medium',
      'estimatedMinutes': 30,
    };
  }

  /// Break down a goal into subtasks
  Future<List<Map<String, dynamic>>> breakdownGoal(String goal) async {
    final prompt =
        '''Break this goal into 3-6 specific, actionable subtasks with time estimates.
Goal: "$goal"
Respond ONLY with JSON array: [{"title": "...", "estimatedMinutes": N}, ...]
No explanation, just the JSON array.''';

    try {
      final response = await chat([
        {'role': 'user', 'content': prompt}
      ]);

      final jsonMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(response);
      if (jsonMatch != null) {
        final list = jsonDecode(jsonMatch.group(0)!) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    return [
      {'title': 'Get started on: $goal', 'estimatedMinutes': 15}
    ];
  }

  /// Reframe an anxiety-inducing task
  Future<String> reframeTask(String anxiousTitle) async {
    final prompt =
        '''Reframe this anxiety-inducing task title into something calm and actionable.
Original: "$anxiousTitle"
Respond with just the reframed title, nothing else. Max 8 words.''';

    final response = await chat([
      {'role': 'user', 'content': prompt}
    ]);
    return response.trim().replaceAll('"', '');
  }

  /// Generate contextual motivational quote
  Future<String> generateQuote({String? currentWork}) async {
    final prompt = currentWork != null
        ? 'Generate a short motivational quote relevant to someone working on "$currentWork". 1-2 sentences max. No attribution needed.'
        : 'Generate a short, unique motivational quote about productivity and flow. 1-2 sentences max. No attribution needed.';

    return await chat([
      {'role': 'user', 'content': prompt}
    ]);
  }

  /// Generate weekly review narrative
  Future<String> generateWeeklyReview({
    required int tasksCompleted,
    required int totalTasks,
    required int focusMinutes,
    required int streak,
    required double completionRate,
    required String bestDay,
    required Map<String, int> categoryBreakdown,
  }) async {
    final prompt =
        '''Write a personal weekly review narrative for Noel.
Stats: $tasksCompleted/$totalTasks tasks completed (${ (completionRate * 100).round()}% completion rate).
Focus time: $focusMinutes minutes. Current streak: $streak days.
Best day: $bestDay.
Category breakdown: $categoryBreakdown
Keep it to 3-4 sentences. Be insightful about patterns. End with one suggestion for next week.''';

    return await chat([
      {'role': 'user', 'content': prompt}
    ]);
  }

  /// Suggest tasks based on patterns
  Future<String> suggestTasks({
    required String dayOfWeek,
    required int hour,
    required List<String> recentCategories,
    required int completedToday,
  }) async {
    final prompt =
        '''It's $dayOfWeek at ${hour}:00. Noel has completed $completedToday tasks today.
Recent categories they work on: ${recentCategories.take(5).join(', ')}.
Suggest 2-3 tasks they might want to do right now, based on time of day and patterns.
Keep suggestions brief and specific. One per line.''';

    return await chat([
      {'role': 'user', 'content': prompt}
    ]);
  }
}
