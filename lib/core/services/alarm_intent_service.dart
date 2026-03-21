// lib/core/services/alarm_intent_service.dart
// Uses Android system intents to set alarms in Clock app & Google Calendar
// Much more reliable than local notifications

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AlarmIntentService {
  static final AlarmIntentService _instance = AlarmIntentService._internal();
  AlarmIntentService._internal();
  static AlarmIntentService get instance => _instance;

  // ─── SET ALARM IN CLOCK APP ───────────────────────────────────────────────
  /// Opens the system Clock app with alarm pre-filled.
  /// User just taps Save — no permission issues.
  Future<bool> setAlarmInClock({
    required DateTime alarmTime,
    required String taskTitle,
    bool skipUI = false, // false = show clock UI so user can confirm
  }) async {
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.HOUR': alarmTime.hour,
          'android.intent.extra.alarm.MINUTES': alarmTime.minute,
          'android.intent.extra.alarm.MESSAGE': taskTitle,
          'android.intent.extra.alarm.SKIP_UI': skipUI,
          'android.intent.extra.alarm.VIBRATE': true,
        },
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('Clock alarm error: $e');
      return false;
    }
  }

  // ─── SET REMINDER IN CLOCK APP ────────────────────────────────────────────
  /// Opens Clock app with a timer / reminder
  Future<bool> setReminderInClock({
    required DateTime reminderTime,
    required String taskTitle,
  }) async {
    try {
      // Compute minutes from now
      final minutesFromNow =
          reminderTime.difference(DateTime.now()).inMinutes;
      if (minutesFromNow <= 0) return false;

      final intent = AndroidIntent(
        action: 'android.intent.action.SET_TIMER',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.LENGTH': minutesFromNow * 60, // seconds
          'android.intent.extra.alarm.MESSAGE': taskTitle,
          'android.intent.extra.alarm.SKIP_UI': false,
        },
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('Clock reminder error: $e');
      return false;
    }
  }

  // ─── ADD EVENT TO GOOGLE CALENDAR ─────────────────────────────────────────
  /// Opens Google Calendar "New Event" screen with task details prefilled.
  Future<bool> addToGoogleCalendar({
    required String taskTitle,
    required DateTime startTime,
    String? description,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final endTime = startTime.add(duration);
      // Format: YYYYMMDDTHHmmssZ
      final fmt = DateFormat("yyyyMMdd'T'HHmmss");
      final start = fmt.format(startTime.toUtc()) + 'Z';
      final end = fmt.format(endTime.toUtc()) + 'Z';

      final encodedTitle = Uri.encodeComponent(taskTitle);
      final encodedDesc =
          Uri.encodeComponent(description ?? 'Added from Mindful Flow');

      final url =
          'https://calendar.google.com/calendar/r/eventedit'
          '?text=$encodedTitle'
          '&dates=$start/$end'
          '&details=$encodedDesc'
          '&sf=true';

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      print('Google Calendar error: $e');
      return false;
    }
  }

  // ─── ADD TO SYSTEM CALENDAR (via Android intent) ──────────────────────────
  /// Uses Android INSERT intent for calendar — works with any calendar app
  Future<bool> addToSystemCalendar({
    required String taskTitle,
    required DateTime startTime,
    String? description,
    Duration duration = const Duration(hours: 1),
  }) async {
    try {
      final endTime = startTime.add(duration);

      final intent = AndroidIntent(
        action: 'android.intent.action.INSERT',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        type: 'vnd.android.cursor.item/event',
        arguments: <String, dynamic>{
          'title': taskTitle,
          'description': description ?? 'Added from Mindful Flow',
          'beginTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
          'allDay': false,
          'hasAlarm': 1,
        },
      );
      await intent.launch();
      return true;
    } catch (e) {
      print('System calendar error: $e');
      return false;
    }
  }
}