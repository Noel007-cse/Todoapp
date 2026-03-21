// lib/core/notification/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'mindful_flow_v4';
  static const String _channelName = 'Mindful Flow Notifications';
  static const String _channelDesc = 'Task reminders and alarms';

  NotificationService._internal();

  static NotificationService get instance => _instance;

  // ─── INITIALIZE ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    tzData.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Handle tap — you can navigate here later
        print('Notification tapped: ${response.payload}');
      },
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Request notification permission (Android 13+)
      await androidImpl.requestNotificationsPermission();

      // Request exact alarm permission (Android 12+)
      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (_) {}

      // Create notification channel
      // NOTE: Using default sound first to guarantee it works.
      // If you want custom sound, add notification.mp3 to
      // android/app/src/main/res/raw/ and uncomment the sound line.
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        // Uncomment below ONLY if notification.mp3 exists in res/raw/
        // sound: RawResourceAndroidNotificationSound('notification'),
      );

      await androidImpl.createNotificationChannel(channel);
    }
  }

  // ─── INSTANT NOTIFICATION (for testing) ───────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ─── SCHEDULE NOTIFICATION ────────────────────────────────────────────────
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      print('Skipping past notification: "$title" at $scheduledDate');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: title,
      styleInformation: BigTextStyleInformation(body),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      print('✅ Scheduled "$title" at $scheduledDate (id: $id)');
    } catch (e) {
      print('❌ Failed to schedule "$title": $e');
      // Try showing immediately as fallback
      await showNotification(
          id: id, title: title, body: body, payload: payload);
    }
  }

  // ─── CANCEL ───────────────────────────────────────────────────────────────
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}