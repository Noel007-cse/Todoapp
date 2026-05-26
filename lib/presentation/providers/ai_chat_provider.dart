// lib/presentation/providers/ai_chat_provider.dart — SahayaK Chat

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/hive_models.dart';
import '../../core/services/groq_ai_service.dart';

class AIChatProvider extends ChangeNotifier {
  late Box<ChatMessage> _chatBox;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialised = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isInitialised => _isInitialised;

  final GroqAIService _ai = GroqAIService.instance;

  AIChatProvider() {
    _init();
  }

  Future<void> _init() async {
    _chatBox = await Hive.openBox<ChatMessage>('chat_messages');
    _messages = _chatBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Add welcome message if empty
    if (_messages.isEmpty) {
      await _addAIMessage(
        _getContextGreeting(),
        actions: ['Summarize my week', 'Schedule a break', 'Break down a goal'],
      );
    }
    _isInitialised = true;
    notifyListeners();
  }

  String _getContextGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final dayName = dayNames[weekday - 1];

    String timeContext;
    if (hour < 12) {
      timeContext = "It's $dayName morning";
    } else if (hour < 17) {
      timeContext = "It's $dayName afternoon";
    } else {
      timeContext = "It's $dayName evening";
    }

    if (weekday == 5 && hour >= 15) {
      timeContext += ", almost the weekend";
    } else if (weekday == 1 && hour < 12) {
      timeContext += " — fresh start to the week";
    }

    return "$timeContext. How are you feeling?\n\nHello, I'm **SahayaK**. I'm here to help you stay focused, organised, and well. Shall we plan your day or tackle something specific?";
  }

  Future<void> sendMessage(String text, {String? taskContext}) async {
    // Add user message
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatBox.put(userMsg.id, userMsg);
    _messages.add(userMsg);
    notifyListeners();

    // Get AI response
    _isLoading = true;
    notifyListeners();

    final history = _messages.takeLast(10).map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }).toList();

    final response = await _ai.chat(
      history.cast<Map<String, String>>(),
      additionalContext: taskContext,
    );

    _isLoading = false;

    await _addAIMessage(response);
  }

  Future<void> _addAIMessage(String content,
      {List<String>? actions}) async {
    final aiMsg = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      actionButtons: actions,
    );
    await _chatBox.put(aiMsg.id, aiMsg);
    _messages.add(aiMsg);
    notifyListeners();
  }

  Future<void> handleQuickAction(String action) async {
    await sendMessage(action);
  }

  Future<String> getDailyBriefing({
    required int pendingTasks,
    required int completedYesterday,
    required String topTask,
    required int streak,
  }) async {
    final now = DateTime.now();
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    return await _ai.generateBriefing(
      userName: 'Noel',
      pendingTasks: pendingTasks,
      completedYesterday: completedYesterday,
      topTaskTitle: topTask,
      currentStreak: streak,
      dayOfWeek: dayNames[now.weekday - 1],
      hour: now.hour,
    );
  }

  Future<void> clearChat() async {
    await _chatBox.clear();
    _messages.clear();
    await _addAIMessage(
      _getContextGreeting(),
      actions: ['Summarize my week', 'Schedule a break', 'Break down a goal'],
    );
  }
}

extension TakeLast<T> on List<T> {
  List<T> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
